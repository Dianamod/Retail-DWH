CREATE OR REPLACE PROCEDURE initial_load_fct_sales()
LANGUAGE plpgsql
AS $$
DECLARE 
    v_insert_count INTEGER;
BEGIN
WITH new_sales AS (
        SELECT
            s.event_dt AS event_dt,
            COALESCE(c.customer_surr_id, -1) AS customer_surr_id,
            COALESCE(p.product_surr_id, -1) AS product_surr_id,
            COALESCE(st.store_surr_id, -1) AS store_surr_id,
            COALESCE(sh.shipping_surr_id, -1) AS shipping_surr_id,
            COALESCE(sc.sales_channel_surr_id, -1) AS channel_surr_id,
            COALESCE(e.employee_surr_id, -1) AS employee_surr_id,
            s.order_unit_price AS fct_sales_unit_price,
            s.order_quantity AS fct_sales_order_quantity,
            s.order_unit_cost AS fct_sales_unit_cost,
            s.order_total_cost AS fct_sales_cost,
            s.order_revenue AS fct_sales_revenue,
            (s.order_revenue - s.order_total_cost) AS fct_sales_profit,
            ROUND((s.order_revenue::NUMERIC - s.order_total_cost::NUMERIC) / NULLIF(s.order_revenue::NUMERIC, 0) * 100, 0) AS fct_sales_gross_margin,
			round(s.order_revenue::numeric/order_quantity::numeric) as fct_avg_order_value,
            CURRENT_DATE AS insert_dt,
            CURRENT_DATE AS update_dt
			from 3nf.ce_sales s 
			left join dm.dim_customers c on
			s.customer_id::varchar=c.customer_src_id 
			left join dm.dim_employees_scd e on
			s.employee_id ::varchar=e.employee_src_id and upper(e.is_active)='Y'
			left join dm.dim_products p on
			s.product_id ::varchar=p.product_src_id 
			left join dm.dim_sales_channels  sc on
			s.sales_channel_id::varchar= sc.sales_channel_src_id 
			left join dm.dim_shippings sh on
			concat(s.shipping_carrier_id,s.shipping_method_id)::varchar=sh.shipping_src_id 
			left join dm.dim_stores st on
			s.store_id ::varchar=st.store_src_id 
			left join dm.dim_times dt on
			s.event_dt =dt.event_dt
    ) 

    INSERT INTO dm.fct_sales_dd (
        event_dt, 
        customer_surr_id, 
        product_surr_id, 
        store_surr_id, 
        shipping_surr_id, 
        channel_surr_id, 
        employee_surr_id, 
        fct_sales_unit_price, 
        fct_sales_order_quantity, 
        fct_sales_unit_cost,
        fct_sales_cost,
        fct_sales_revenue,
        fct_sales_profit,
        fct_sales_gross_margin,
fct_avg_order_value,
        insert_dt,
        update_dt
    )
    SELECT *
    FROM new_sales n
    WHERE NOT EXISTS (
        SELECT 1 FROM dm.fct_sales_dd f  
        JOIN dm.dim_employees_scd d 
        ON f.employee_surr_id = d.employee_surr_id
    	JOIN dm.dim_employees_scd cd 
        ON d.employee_src_id = cd.employee_src_id  -- Compare on src_id
        AND cd.is_active = 'Y' 
        WHERE f.event_dt = n.event_dt
        AND f.product_surr_id = n.product_surr_id
        AND f.customer_surr_id = n.customer_surr_id
        AND f.channel_surr_id = n.channel_surr_id
        AND f.store_surr_id = n.store_surr_id
        AND f.shipping_surr_id = n.shipping_surr_id
    );


    GET DIAGNOSTICS v_insert_count = ROW_COUNT;


    CALL cl.log_procedure_execution_dm('load_initial_fct_sales', v_insert_count, 'Successfully loaded full fact sales data.');


    RAISE NOTICE 'Procedure executed successfully. Rows affected: %', v_insert_count;

EXCEPTION WHEN OTHERS THEN

    CALL cl.log_procedure_execution_dm('load_initial_fct_sales', 0, 'Error: ' || SQLERRM);
    RAISE NOTICE 'Error in procedure load_initital_fct_sales: %', SQLERRM;
END $$;



