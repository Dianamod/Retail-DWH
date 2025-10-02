begin;
CREATE OR REPLACE PROCEDURE cl.load_dim_customers_scd_type_1()
LANGUAGE plpgsql
AS $$
DECLARE
    v_affected_rows INT := 0;
BEGIN

    MERGE INTO dm.dim_customers AS target
    USING (
        SELECT 
            cc.customer_first_name as customer_first_name,
            cc.customer_last_name as customer_last_name,
            coalesce(cc.customer_address_id,-1) as customer_address_id,
            COALESCE(ca.address, 'n.a') AS customer_address,
            COALESCE(ca.address_state_id, -1) AS customer_state_id,
            COALESCE(cs.state, 'n.a') AS customer_state,
            COALESCE(cs.state_country_id, -1) AS customer_country_id,
            COALESCE(cc2.country, 'n.a') AS customer_country,
            CURRENT_DATE AS insert_dt,
            CURRENT_DATE AS update_dt,
            cc.customer_id AS customer_src_id,
            'bl_3nf' as source_system,
            'bl_3nf_ce_customers' as source_entity
        FROM 3nf.ce_customers cc
        LEFT JOIN 3nf.ce_addresses ca 
            ON cc.customer_address_id = ca.address_id
            AND cc.source_system = ca.source_system 
            AND cc.source_entity = ca.source_entity
        LEFT JOIN 3nf.ce_states cs 
            ON ca.address_state_id = cs.state_id
            AND ca.source_system = cs.source_system 
            AND ca.source_entity = cs.source_entity
        LEFT JOIN 3nf.ce_countries cc2 
            ON cs.state_country_id = cc2.country_id
            AND ca.source_system = cc2.source_system 
            AND ca.source_entity = cc2.source_entity
        WHERE cc.customer_id <> -1
    ) AS source
    ON target.customer_src_id = source.customer_src_id::varchar

    WHEN MATCHED AND (
        upper(target.customer_first_name) <> upper(source.customer_first_name) OR
        upper(target.customer_last_name) <> upper(source.customer_last_name)
    ) THEN 
        UPDATE SET 
            customer_first_name = source.customer_first_name,
            customer_last_name = source.customer_last_name,
            update_dt = CURRENT_DATE

    WHEN NOT MATCHED THEN
        INSERT (customer_first_name, customer_last_name,customer_address_id,customer_address,customer_state_id,customer_state, customer_country_id,
				customer_country,insert_dt, update_dt,customer_src_id, source_system, source_entity)
        VALUES ( source.customer_first_name, source.customer_last_name, 
                source.customer_address_id, source.customer_address, source.customer_state_id,source.customer_state,source.customer_country_id,
				source.customer_country, source.insert_dt, source.update_dt, source.customer_src_id, source.source_system, source.source_entity);


    GET DIAGNOSTICS v_affected_rows = ROW_COUNT;

 
    CALL cl.log_procedure_execution_dm('load_dim_customers_scd_type_1', v_affected_rows, 'Dim Customers SCD type 1 Load');


    RAISE NOTICE 'Procedure executed. Affected rows: %', v_affected_rows;

EXCEPTION WHEN OTHERS THEN

    CALL cl.log_procedure_execution_dm('load_dim_customers_scd_type_1', 0, SQLERRM);
    RAISE NOTICE 'Error in procedure load_dim_customers_scd_type_1: %', SQLERRM;
END;
$$;

commit;



