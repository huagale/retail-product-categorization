-- итоговая разметка и результаты
-- mysql, база my_project

-- 1. категория, подкатегория и статус
create or replace view my_project.footwear_classified as
select
    uniq_id,
    product_name,
    case
        when predicted_type_v4 = 'Shoe Care' then 'Shoe Care & Accessories'
        when predicted_type_v4 is not null then 'Footwear'
        else null
    end as category,
    predicted_type_v4 as subcategory,
    case
        when predicted_type_v4 is not null then 'Размечен'
        else 'Требуется проверка'
    end as labeling_status
from my_project.footwear_rules_v4;

-- вывод: в итоговом представлении у каждого товара есть категория, подкатегория и статус обработки.
-- вывод: у товаров без подходящего правила категория и подкатегория остаются null.

-- 2. итоговый охват
select count(*) as total_products,
       count(subcategory) as labeled_products,
       count(*) - count(subcategory) as for_review,
       round(100.0 * count(subcategory) / nullif(count(*), 0), 2) as coverage_pct
from my_project.footwear_classified;

-- вывод: из 1 121 товаров разметку получили 1 032 — 92,06%.
-- вывод: 89 товаров, или 7,94%, остались со статусом «требуется проверка».

-- 3. распределение по подкатегориям
select category, subcategory, labeling_status,
       count(*) as products,
       round(100.0 * count(*) / nullif(
           (select count(*) from my_project.footwear_classified), 0
       ), 2) as share_pct
from my_project.footwear_classified
group by category, subcategory, labeling_status
order by products desc, subcategory;

-- вывод: самые крупные итоговые группы — wedges: 207, boots: 177 и loafers: 156.
-- вывод: крем для обуви выделен отдельно: shoe care & accessories → shoe care.

-- 4. примеры итоговых строк
select uniq_id, product_name, category, subcategory, labeling_status
from my_project.footwear_classified
order by labeling_status, subcategory, product_name, uniq_id
limit 50;

-- вывод: выгрузка показывает формат результата, но ограничена 50 строками.
-- вывод: для полного каталога нужно убрать limit 50.

-- 5. названия для дополнительной проверки
select product_name, count(*) as products
from my_project.footwear_classified
where subcategory is null
group by product_name
order by products desc, product_name
limit 40;

-- вывод: среди оставшихся названий есть slip on, lace up и party wear, а также названия моделей без вида обуви.
-- вывод: для них лучше проверить дополнительные сведения, чем назначать подкатегорию по бренду.
