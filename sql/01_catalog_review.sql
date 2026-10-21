-- проверка каталога и выбор группы товаров
-- mysql, база my_project

-- 1. объем каталога и пропуски
select
    count(*) as total_products,
    sum(product_name is null or trim(product_name) = '') as missing_name,
    sum(description is null or trim(description) = '') as missing_description,
    sum(product_category_tree is null or trim(product_category_tree) = '') as missing_category
from my_project.flipkart_com_ecommerce_sample;

-- вывод: в каталоге 20 000 записей. названия есть у всех товаров, описание отсутствует у двух.
-- вывод: для первой версии правил использую названия, поэтому эти два пропуска не мешают разметке.

-- 2. повторяющиеся идентификаторы
select uniq_id, count(*) as occurrences
from my_project.flipkart_com_ecommerce_sample
group by uniq_id
having count(*) > 1
order by occurrences desc, uniq_id;

-- вывод: запрос не вернул строк: повторений uniq_id не найдено.

-- 3. структура каталога по первому уровню
select
    replace(replace(
        substring_index(product_category_tree, ' >> ', 1),
        '["', ''), '"]', '') as main_category,
    count(*) as products,
    round(100.0 * count(*) / nullif(
        (select count(*) from my_project.flipkart_com_ecommerce_sample), 0
    ), 2) as share_pct
from my_project.flipkart_com_ecommerce_sample
group by main_category
order by products desc, main_category;

-- вывод: самые крупные ветки — clothing: 6 198, jewellery: 3 531 и footwear: 1 227.
-- вывод: вместе это 54,78% каталога. в отдельных строках вместо ветки записано название товара, поэтому не считаю все значения полноценными категориями.

-- 4. объем обуви и число разных названий
select
    count(*) as footwear_rows,
    count(distinct product_name) as different_names
from my_project.flipkart_com_ecommerce_sample
where product_category_tree like '["Footwear >> %';

-- вывод: в ветке footwear 1 227 записей и 830 разных названий.
-- вывод: одинаковые названия не удаляю: у товаров разные идентификаторы, а для проверки правил беру разные названия.

-- 5. группы внутри обуви
select
    replace(substring_index(
        substring_index(product_category_tree, ' >> ', 2), ' >> ', -1
    ), '"]', '') as source_group,
    count(*) as products
from my_project.flipkart_com_ecommerce_sample
where product_category_tree like '["Footwear >> %'
group by source_group
order by products desc, source_group;

-- вывод: женская обувь — 781 запись, мужская — 340, детская — 105. еще у одной записи нестандартный путь.
-- вывод: для правил выбираю мужскую и женскую обувь: 1 121 запись. детскую оставляю за рамками этой версии.

-- 6. самые частые полные пути обуви
select product_category_tree, count(*) as products
from my_project.flipkart_com_ecommerce_sample
where product_category_tree like '["Footwear >> %'
group by product_category_tree
order by products desc, product_category_tree
limit 20;

-- вывод: в исходном дереве boots и loafers могут находиться внутри casual shoes.
-- вывод: поэтому прямое сравнение нашей метки с третьим уровнем дерева может показать расхождение, которое не является ошибкой.

-- 7. повторения названий обуви
select product_name, count(*) as products
from my_project.flipkart_com_ecommerce_sample
where product_category_tree like '["Footwear >> %'
group by product_name
having count(*) > 1
order by products desc, product_name
limit 20;

-- вывод: my foot women flats встречается 21 раз, kielz ladies boots — 15 раз.
-- вывод: случайная выборка строк могла бы несколько раз проверить одно название и оставить другие без внимания.
