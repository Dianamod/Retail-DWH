begin;

CREATE OR REPLACE PROCEDURE cl.load_ce_customers_scd_type_1()
LANGUAGE plpgsql
AS $$
DECLARE
    v_updated_count INT := 0;
    v_inserted_count INT := 0;
    v_updated_count_online INT := 0;
    v_inserted_count_online INT := 0;
    v_message TEXT;
BEGIN

    CREATE TEMP TABLE tmp_customer_transactions AS
    SELECT 
        "Customer ID", 
        customer_first_name,
        customer_last_name,
        ROW_NUMBER() OVER (PARTITION BY "Customer ID" ORDER BY event_dt::date DESC) AS rn
    FROM sa_offline_sales.src_offline_sales;


    MERGE INTO 3nf.ce_customers AS target
    USING (
        SELECT 
            COALESCE("Customer ID", 'n.a') AS customer_src_id, 
            COALESCE(UPPER(customer_first_name), 'n.a') AS customer_first_name,
            COALESCE(UPPER(customer_last_name), 'n.a') AS customer_last_name,
            -1 AS customer_address_id,
            CURRENT_DATE AS insert_dt,
            CURRENT_DATE AS update_dt,
            'sa_offline_sales' AS source_system,
            'src_offline_sales' AS source_entity
        FROM tmp_customer_transactions
        WHERE rn = 1
    ) AS source
    ON target.customer_src_id = source.customer_src_id
    AND target.source_system = source.source_system
    AND target.source_entity = source.source_entity
    WHEN MATCHED AND (  
        upper(target.customer_first_name) <> upper(source.customer_first_name) OR
        upper(target.customer_last_name) <> upper(source.customer_last_name)
    ) THEN 
        UPDATE SET 
            customer_first_name = source.customer_first_name,
            customer_last_name = source.customer_last_name,
            update_dt = CURRENT_DATE;


    GET DIAGNOSTICS v_updated_count = ROW_COUNT;


    MERGE INTO 3nf.ce_customers AS target
    USING (
        SELECT 
            COALESCE("Customer ID", 'n.a') AS customer_src_id, 
            COALESCE(UPPER(customer_first_name), 'n.a') AS customer_first_name,
            COALESCE(UPPER(customer_last_name), 'n.a') AS customer_last_name,
            -1 AS customer_address_id,
            CURRENT_DATE AS insert_dt,
            CURRENT_DATE AS update_dt,
            'sa_offline_sales' AS source_system,
            'src_offline_sales' AS source_entity
        FROM tmp_customer_transactions
        WHERE rn = 1
    ) AS source
    ON target.customer_src_id = source.customer_src_id
    AND target.source_system = source.source_system
    AND target.source_entity = source.source_entity
    WHEN NOT MATCHED THEN  
        INSERT (customer_src_id, customer_first_name, customer_last_name, 
                customer_address_id, insert_dt, update_dt, source_system, source_entity)
        VALUES (source.customer_src_id, source.customer_first_name, source.customer_last_name, 
                source.customer_address_id, source.insert_dt, source.update_dt, source.source_system, source.source_entity);


    GET DIAGNOSTICS v_inserted_count = ROW_COUNT;
   
      CREATE TEMP TABLE tmp_customer_transactions2 AS
    SELECT 
        "Buyer ID", 
        customer_first_name,
        customer_last_name,
        "Customer Addresses",
        ROW_NUMBER() OVER (PARTITION BY "Buyer ID" ORDER BY "Transaction Date"::date DESC) AS rn
    FROM sa_online_sales.src_online_sales s;

  MERGE INTO 3nf.ce_customers AS target
    USING (
	select
		distinct coalesce("Buyer ID",'n.a') as customer_src_id,
		coalesce(upper(customer_first_name),'n.a') as customer_first_name,
		coalesce(upper(customer_last_name),'n.a') as customer_last_name,
		coalesce(a.address_id,-1) as customer_address_id,
		current_date as insert_dt,
		current_date as update_dt,
		'sa_online_sales' as source_system,
		'src_online_sales' as source_entity
		FROM tmp_customer_transactions2 t
		left join 3nf.ce_addresses a on upper(a.address) =upper(t."Customer Addresses")
		WHERE rn = 1
		 ) AS source
    ON target.customer_src_id = source.customer_src_id
    AND target.source_system = source.source_system
    AND target.source_entity = source.source_entity
    WHEN MATCHED AND (  
        upper(target.customer_first_name) <> upper(source.customer_first_name) OR
        upper(target.customer_last_name) <> upper(source.customer_last_name)
    ) THEN 
        UPDATE SET 
            customer_first_name = source.customer_first_name,
            customer_last_name = source.customer_last_name,
            update_dt = CURRENT_DATE;
    
    GET DIAGNOSTICS v_updated_count_online = ROW_COUNT;
   
     MERGE INTO bl_3nf.ce_customers AS target
    USING (
	select
		distinct coalesce("Buyer ID",'n.a') as customer_src_id,
		coalesce(upper(customer_first_name),'n.a') as customer_first_name,
		coalesce(upper(customer_last_name),'n.a') as customer_last_name,
		coalesce(a.address_id,-1) as customer_address_id,
		current_date as insert_dt,
		current_date as update_dt,
		'sa_online_sales' as source_system,
		'src_online_sales' as source_entity
		FROM tmp_customer_transactions2 t
		left join 3nf.ce_addresses a on upper(a.address) =upper(t."Customer Addresses")
		WHERE rn = 1
		 ) AS source
    ON target.customer_src_id = source.customer_src_id
    AND target.source_system = source.source_system
    AND target.source_entity = source.source_entity
    WHEN NOT MATCHED THEN  
        INSERT (customer_src_id, customer_first_name, customer_last_name, 
                customer_address_id, insert_dt, update_dt, source_system, source_entity)
        VALUES (source.customer_src_id, source.customer_first_name, source.customer_last_name, 
                source.customer_address_id, source.insert_dt, source.update_dt, source.source_system, source.source_entity);


    GET DIAGNOSTICS v_inserted_count_online = ROW_COUNT;


    DROP TABLE tmp_customer_transactions;

    IF v_updated_count = 0 AND v_inserted_count = 0 THEN
        v_message := 'No changes detected.';
    ELSE
        v_message := 'Customer data merge successful.';
    END IF;

    CALL cl.log_procedure_execution('load_dim_customers', v_inserted_count, v_updated_count, v_message);

    RAISE NOTICE 'Procedure executed. Inserts: %, Updates: %. Message: %', v_inserted_count+v_inserted_count_online, v_updated_count+v_updated_count_online, v_message;

EXCEPTION WHEN OTHERS THEN
    CALL cl.log_procedure_execution('load_dim_customers', 0, 0, 'Error: ' || SQLERRM);
    RAISE NOTICE 'Error in procedure load_dim_customers: %', SQLERRM;
END;
$$;

commit;