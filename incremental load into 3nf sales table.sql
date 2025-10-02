begin;
CREATE OR REPLACE PROCEDURE load_incremental_sales()
LANGUAGE plpgsql
AS $$
DECLARE
    v_last_load_dt DATE;
    v_rows_offline INT := 0;
    v_rows_online INT := 0;
BEGIN


    -- Load new sales from offline source
with new_sales as (

SELECT
    event_dt::date,
    coalesce(cc.customer_id, -1) AS customer_id,
    coalesce(p.product_id, -1) AS product_id,
    coalesce(round(s1."Order Quantity"::float)::int, 0) AS order_quantity,
    s1."Unit Price"::float AS order_unit_price,
    coalesce(ce.employee_id, -1) AS employee_id,
    coalesce(csc.sales_channel_id, -1) AS sales_channel_id,
    coalesce(cs.store_id, -1) AS store_id,
    -1 AS shipping_carrier_id,
    -1 AS shipping_method_id,
    s1."Unit Cost"::float AS order_unit_cost,
    s1."Cost"::float AS order_total_cost,
    s1.revenue::float AS order_revenue,
    current_date AS insert_dt,
    current_date AS update_date
FROM sa_offline_sales.src_offline_sales s1
LEFT JOIN 3nf.ce_customers cc
    ON upper(cc.customer_src_id) = upper(s1."Customer ID")
    AND upper(cc.source_system) = upper('sa_offline_sales')
    AND upper(cc.source_entity) = upper('src_offline_sales')
LEFT JOIN 3nf.ce_product_subcategories cps
    ON upper(cps.product_subcategory) = upper(s1."Product Subcategory")
    AND upper(cps.source_entity) = upper('src_offline_sales')
    AND upper(cps.source_system) = upper('sa_offline_sales')
LEFT JOIN 3nf.ce_products p
    ON upper(p.product)=upper(SPLIT_PART(s1.product, ',', 1))
    AND p.product_subcategory_id = cps.product_subcategory_id
    AND upper(p.source_system) = upper('sa_offline_sales')
    AND upper(p.source_entity) = upper('src_offline_sales')
    AND upper(p.product_src_id) = COALESCE(upper(SPLIT_PART(s1.product, ',', 1)), 'n.a') || '_'
                                    || COALESCE(ROUND(s1."Frame Size"::float)::int, 0) || '_'
                                    || ROUND(s1."Unit Price"::numeric, 0) || '_'
                                    || cps.product_subcategory_id || '_'
                                    || ROUND(s1."Unit Cost"::numeric, 0)
left join 3nf.ce_employees_scd ce on upper(ce.employee_src_id) =upper(s1.employee_id) and upper(ce.source_system)= upper('sa_offline_sales')
																	and upper(ce.source_entity)=upper('src_offline_sales')
																	and ce.start_dt<=current_date 
																	and ce.end_dt >current_date
left join 3nf.ce_sales_channels csc on upper(csc.sales_channel)=upper(s1.sales_channel) and upper(csc.source_system)= upper('sa_offline_sales')
																	and upper(csc.source_entity)=upper('src_offline_sales')
																	and upper(csc.sales_channel_src_id)= upper(s1.sales_channel)
left join 3nf.ce_stores cs on upper(cs.store_src_id)=upper(s1."Store ID") and upper(cs.source_system)= upper('sa_offline_sales')
																	and upper(cs.source_entity)=upper('src_offline_sales')
																	and upper(cs.store_name)= upper(s1."Store Name")
																	where event_dt::date> (select max(last_load_dt) from load_metadata where table_name='ce_sales')
    )

insert into 3nf.ce_sales (
event_dt,customer_id,product_id,order_quantity,order_unit_price,employee_id,sales_channel_id,
store_id,shipping_carrier_id,shipping_method_id,order_unit_cost,order_total_cost, order_revenue, insert_dt,update_dt)

select
*
from new_sales n
where not exists (select 1 from 3nf.ce_sales o where o.event_dt=n.event_dt
							and o.product_id=n.product_id
							and o.customer_id=n.customer_id
							and o.employee_id=n.employee_id
							and o.sales_channel_id=n.sales_channel_id
							and o.store_id=n.store_id
							and o.shipping_method_id= n.shipping_method_id
							and o.shipping_carrier_id=n.shipping_carrier_id
						)	;			
GET DIAGNOSTICS v_rows_offline = ROW_COUNT;

RAISE NOTICE 'Inserted % rows from offline sales.', v_rows_offline;

    -- Load new sales from online source
   with new_sales2 as (
select
"Transaction Date"::date as event_dt,
coalesce(cc.customer_id,-1)as customer_id,
coalesce(p.product_id,-1) as product_id,
coalesce(round(s1."Order Quantity"::float)::int, 0) as order_quantity,
s1."Unit Price"::float as order_unit_price,
-1 as employee_id,
coalesce(csc.sales_channel_id,-1) as sales_channel_id,
-1 as store_id,
coalesce(c1.shipping_carrier_id,-1) as shipping_carrier_id,
coalesce(c2.shipping_method_id,-1) as shipping_method_id,
s1."Unit Cost"::float as order_unit_cost,
s1."Cost"::float as order_total_cost,
s1.revenue::float as order_revenue,
current_date as insert_dt,
current_date as update_date
from sa_online_sales.src_online_sales s1
left join 3nf.ce_customers cc on cc.customer_src_id=s1."Buyer ID" and upper(cc.source_system)= upper('sa_online_sales') 
																	and upper(cc.source_entity)=upper('src_online_sales')
LEFT JOIN 3nf.ce_product_subcategories cps
    ON upper(cps.product_subcategory) = upper(s1."Subcategory")
    AND upper(cps.source_entity) = upper('src_online_sales')
    AND upper(cps.source_system) = upper('sa_online_sales')
LEFT JOIN 3nf.ce_products p
    ON upper(p.product) = upper(s1.product)
    AND p.product_subcategory_id = cps.product_subcategory_id
    AND upper(p.source_system) = upper('sa_online_sales')
    AND upper(p.source_entity) = upper('src_online_sales')
    AND upper(p.product_src_id) = COALESCE(upper(s1.product), 'n.a') || '_'
                                    || COALESCE(ROUND(s1."Frame Size"::float)::int, 0) || '_'
                                    || ROUND(s1."Unit Price"::numeric, 0) || '_'
                                    || cps.product_subcategory_id || '_'
                                    || ROUND(s1."Unit Cost"::numeric, 0)

left join 3nf.ce_sales_channels csc on upper(csc.sales_channel)=upper(s1.sales_channel) and upper(csc.source_system)= upper('sa_online_sales')
																	and upper(csc.source_entity)=upper('src_online_sales')
left join 3nf.ce_shipping_carriers c1 on upper(c1.shipping_carrier)=upper(s1."Shipping Carriers") 
																	and upper(c1.shipping_carrier_src_id)=upper(s1."Shipping Carriers")
																	and upper(c1.source_system)=upper('sa_online_sales')
																	and upper(c1.source_entity)=upper('src_online_sales')											
left join 3nf.ce_shipping_methods c2 on upper(c2.shipping_method)=upper(s1."Shipping Methods")
																	and upper(c2.shipping_method_src_id)=upper(s1."Shipping Methods")
																	and upper(c2.source_system)=upper('sa_online_sales')
																	and upper(c2.source_entity)=upper('src_online_sales')
																	where "Transaction Date"::date> (select max(last_load_dt) from load_metadata where table_name='ce_sales')
    )

insert into 3nf.ce_sales (
event_dt,customer_id,product_id,order_quantity,order_unit_price,employee_id,sales_channel_id,
store_id,shipping_carrier_id,shipping_method_id,order_unit_cost,order_total_cost, order_revenue, insert_dt,update_dt)

select
*
from new_sales2 n
where not exists (select 1 from 3nf.ce_sales o where o.event_dt=n.event_dt
							and o.product_id=n.product_id
							and o.customer_id=n.customer_id
							and o.employee_id=n.employee_id
							and o.sales_channel_id=n.sales_channel_id
							and o.store_id=n.store_id
							and o.shipping_carrier_id=n.shipping_carrier_id
							and o.shipping_method_id=n.shipping_method_id
						);
 GET DIAGNOSTICS v_rows_online = ROW_COUNT;

    RAISE NOTICE 'Inserted % rows from online sales.', v_rows_online;

    -- Update load log with the latest event date
    UPDATE cl.load_metadata 
    SET last_load_dt = (SELECT MAX(event_dt) FROM 3nf.ce_sales)
    WHERE table_name = 'ce_sales';

    -- Log successful execution
    CALL cl.log_procedure_execution(
        'load_incremental_sales', v_rows_offline + v_rows_online, 0, 'Incremental load completed successfully.'
    );

EXCEPTION 
    WHEN OTHERS THEN
        -- Log error and raise notice
        CALL cl.log_procedure_execution(
            'load_incremental_sales', 0, 0, 'Error: ' || SQLERRM
        );
        RAISE NOTICE 'Error in procedure load_incremental_sales: %', SQLERRM;
END;
$$;

commit;