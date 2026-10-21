-- первая версия правил по названию товара
-- mysql, база my_project

-- 1. правила и их порядок
create or replace view my_project.footwear_rules_v1 as
select
    uniq_id,
    product_name,
    product_category_tree,
    substring_index(
        substring_index(product_category_tree, ' >> ', 2), ' >> ', -1
    ) as source_group,
    replace(substring_index(
        substring_index(product_category_tree, ' >> ', 3), ' >> ', -1
    ), '"]', '') as source_type,
    case
        when lower(product_name) like '%wedge%' then 'Wedges'
        when lower(product_name) like '%heel%' then 'Heels'
        when lower(product_name) like '%bellies%'
          or lower(product_name) like '%ballerina%' then 'Ballerinas'
        when lower(product_name) like '%flat%' then 'Flats'
        when lower(product_name) like '%sandal%'
          or lower(product_name) like '%floater%' then 'Sandals & Floaters'
        when lower(product_name) like '%slipper%'
          or lower(product_name) like '%flip flop%' then 'Slippers & Flip Flops'
        when lower(product_name) like '%running%'
          or lower(product_name) like '%training%'
          or lower(product_name) like '%football%'
          or lower(product_name) like '%sports shoe%' then 'Sports Shoes'
        when lower(product_name) like '%boot%' then 'Boots'
        when lower(product_name) like '%loafer%'
          or lower(product_name) like '%casual%'
          or lower(product_name) like '%sneaker%' then 'Casual Shoes'
        when lower(product_name) like '%formal%' then 'Formal Shoes'
        else null
    end as predicted_type
from my_project.flipkart_com_ecommerce_sample
where product_category_tree like '["Footwear >> Women''s Footwear >> %'
   or product_category_tree like '["Footwear >> Men''s Footwear >> %';

-- вывод: правила ищут слова только в product_name. исходное дерево задает область проекта и помогает разбирать результат.
-- вывод: case выбирает первое подходящее условие: например, sandals проверяется раньше sports shoes, а boots — раньше casual shoes.

-- 2. охват первой версии
select
    count(*) as total_products,
    count(predicted_type) as labeled_products,
    count(*) - count(predicted_type) as without_label,
    round(100.0 * count(predicted_type) / nullif(count(*), 0), 2) as coverage_pct
from my_project.footwear_rules_v1;

-- вывод: первая версия разметила 1 009 из 1 121 товаров. охват — 90,01%, без метки осталось 112 товаров.

-- 3. распределение первых меток
select coalesce(predicted_type, 'без правила') as predicted_type,
       count(*) as products
from my_project.footwear_rules_v1
group by predicted_type
order by products desc, predicted_type;

-- вывод: самая большая группа — casual shoes: 238 товаров. в нее пока входят и лоферы.
-- вывод: это повод проверить, стоит ли выделить более конкретный тип.

-- 4. товары без подходящего правила
select product_name, source_group, source_type, count(*) as products
from my_project.footwear_rules_v1
where predicted_type is null
group by product_name, source_group, source_type
order by products desc, product_name, source_group, source_type
limit 30;

-- вывод: среди пропусков есть slip on, lace up, canvas shoes и крем для обуви.
-- вывод: для canvas shoes и средства ухода можно добавить отдельные правила. slip on и lace up сами по себе не дают нужной подкатегории.

-- 5. почему boots нельзя проверять только по третьему уровню
select product_category_tree, count(*) as products
from my_project.footwear_rules_v1
where predicted_type = 'Boots'
group by product_category_tree
order by products desc, product_category_tree
limit 15;

-- вывод: в исходных данных встречается путь casual shoes → boots.
-- вывод: метка boots подробнее, чем casual shoes, поэтому такое отличие не записываю в ошибки алгоритма.
