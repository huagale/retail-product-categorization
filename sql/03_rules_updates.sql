-- доработка правил по найденным случаям
-- mysql, база my_project

-- 1. средства ухода и лоферы
create or replace view my_project.footwear_rules_v2 as
select
    v1.*,
    case
        when lower(product_name) like '%shoe cream%'
          or lower(product_name) like '%shoe polish%'
          or lower(product_name) like '%shoe cleaner%' then 'Shoe Care'
        when lower(product_name) like '%loafer%' then 'Loafers'
        else predicted_type
    end as predicted_type_v2
from my_project.footwear_rules_v1 v1;

-- вывод: крем для обуви получил метку shoe care, а лоферы выделены в отдельный тип loafers.
-- вывод: эти два правила могут заменить более общую метку первой версии, поэтому стоят перед возвратом predicted_type.

-- 2. boat shoes
create or replace view my_project.footwear_rules_v3 as
select
    v2.*,
    case
        when predicted_type_v2 is not null then predicted_type_v2
        when lower(product_name) like '%boat shoes%' then 'Casual Shoes'
        else null
    end as predicted_type_v3
from my_project.footwear_rules_v2 v2;

-- вывод: названия с boat shoes отношу к casual shoes, если более ранние правила не дали метку.
-- вывод: так обрабатывается clarks dunbar racer boat shoes из контрольных примеров.

-- 3. дополнительные виды спортивной и повседневной обуви
create or replace view my_project.footwear_rules_v4 as
select
    v3.*,
    case
        when predicted_type_v3 is not null then predicted_type_v3
        when lower(product_name) like '%basketball shoes%'
          or lower(product_name) like '%walking shoes%' then 'Sports Shoes'
        when lower(product_name) like '%canvas shoes%' then 'Casual Shoes'
        else null
    end as predicted_type_v4
from my_project.footwear_rules_v3 v3;

-- вывод: basketball shoes и walking shoes добавлены к sports shoes, canvas shoes — к casual shoes.
-- вывод: правила основаны на видах обуви в названиях, а не на брендах или номерах моделей.

-- 4. как изменился охват
select 'v1' as version,
       count(*) as total_products,
       count(predicted_type) as labeled_products,
       count(*) - count(predicted_type) as without_label,
       round(100.0 * count(predicted_type) / nullif(count(*), 0), 2) as coverage_pct
from my_project.footwear_rules_v1
union all
select 'v2', count(*), count(predicted_type_v2),
       count(*) - count(predicted_type_v2),
       round(100.0 * count(predicted_type_v2) / nullif(count(*), 0), 2)
from my_project.footwear_rules_v2
union all
select 'v3', count(*), count(predicted_type_v3),
       count(*) - count(predicted_type_v3),
       round(100.0 * count(predicted_type_v3) / nullif(count(*), 0), 2)
from my_project.footwear_rules_v3
union all
select 'v4', count(*), count(predicted_type_v4),
       count(*) - count(predicted_type_v4),
       round(100.0 * count(predicted_type_v4) / nullif(count(*), 0), 2)
from my_project.footwear_rules_v4;

-- вывод: охват вырос с 90,01% до 92,06%: первая версия дала 1 009 меток, итоговая — 1 032.
-- вывод: для второй версии зафиксировано 1 010 меток. охват показывает наличие метки, а не ее правильность.

-- 5. какие товары получили новую или другую метку
select product_name,
       predicted_type as type_v1,
       predicted_type_v4 as type_v4,
       count(*) as products
from my_project.footwear_rules_v4
where not (predicted_type <=> predicted_type_v4)
group by product_name, predicted_type, predicted_type_v4
order by products desc, product_name, type_v1, type_v4;

-- вывод: здесь видны два разных изменения: заполнение пропусков и уточнение старых меток.
-- вывод: перенос лоферов из casual shoes в loafers меняет распределение, но сам по себе не увеличивает охват.
