-- контрольные примеры для сравнения версий
-- mysql, база my_project

-- 1. отдельная таблица контрольных примеров
create table if not exists my_project.footwear_validation_reference (
    validation_id int primary key,
    product_name varchar(255) not null,
    manual_type varchar(50),
    comment varchar(255)
);

-- вывод: использую отдельную таблицу, чтобы не менять footwear_validation из рабочей базы.
-- вывод: метки ставились по названиям. исходные категории в качестве готового ответа не использовались.

-- 2. фиксированный набор из 50 разных названий
insert ignore into my_project.footwear_validation_reference
    (validation_id, product_name, manual_type, comment)
values
    (1, 'Parbat Nova-Orng-Strips Running Shoes', 'Sports Shoes', null),
    (2, 'MSL Classic Women Wedges', 'Wedges', null),
    (3, 'Relexop Women Wedges', 'Wedges', null),
    (4, 'Pruto Monk Strap', null, 'не определить уверенно только по названию'),
    (5, 'Woly Smooth Leather Shoe Cream', 'Shoe Care', 'средство ухода, а не обувь'),
    (6, 'Mochi Classic Loafers', 'Loafers', null),
    (7, 'INDIANO Loafers', 'Loafers', null),
    (8, 'Rialto Women Heels', 'Heels', null),
    (9, 'Yahe Women Heels', 'Heels', null),
    (10, 'Adorn Women Wedges', 'Wedges', null),
    (11, 'Anira Fashion Women Wedges', 'Wedges', null),
    (12, 'Zobello Casual Shoes', 'Casual Shoes', null),
    (13, 'Aris Mart Women Wedges', 'Wedges', null),
    (14, 'Indulgence Brocade Finish Low Women Wedges', 'Wedges', null),
    (15, 'Lyc Women Heels', 'Heels', null),
    (16, 'Marc Loire Women Heels', 'Heels', null),
    (17, 'Leeway Women Wedges', 'Wedges', null),
    (18, 'Shoe Centre Women Heels', 'Heels', null),
    (19, 'Cobbler''s Thread Women Wedges', 'Wedges', null),
    (20, 'Wave Walk Royal Boots', 'Boots', null),
    (21, 'Ffc New York Women Heels', 'Heels', null),
    (22, 'Alberto Torresi Loafers', 'Loafers', null),
    (23, 'Mod-Inn Women Wedges', 'Wedges', null),
    (24, 'Trotters Women Wedges', 'Wedges', null),
    (25, 'Adidas Training & Gym Shoes', 'Sports Shoes', null),
    (26, 'Clarks Dunbar Racer Boat Shoes', 'Casual Shoes', null),
    (27, 'GLAMWALK Festive Bellies', 'Ballerinas', null),
    (28, 'DressBerry Bellies', 'Ballerinas', null),
    (29, 'Belle Gambe Boots', 'Boots', null),
    (30, 'Annabelle by Pantaloons Women Wedges', 'Wedges', null),
    (31, 'Butterfly Women Wedges', 'Wedges', null),
    (32, 'Abr Casual Shoes', 'Casual Shoes', null),
    (33, 'Pantof Women Flats', 'Flats', null),
    (34, 'Nell Women Heels', 'Heels', null),
    (35, 'La Briza Andria Boots', 'Boots', null),
    (36, 'Select Sporty Running Shoes', 'Sports Shoes', null),
    (37, 'Aerosoft Slippers', 'Slippers & Flip Flops', null),
    (38, 'Knotty Derby James Ankle Sneakers', 'Casual Shoes', null),
    (39, 'Jon Pep Slippers', 'Slippers & Flip Flops', null),
    (40, 'Muskan Women Wedges', 'Wedges', null),
    (41, 'Studio 9 Studded Loafers', 'Loafers', null),
    (42, 'NELL Women Wedges', 'Wedges', null),
    (43, 'Klaur Melbourne Women Heels', 'Heels', null),
    (44, 'AS Sports Airfort Boots', 'Boots', null),
    (45, 'Shoe Bazar Women Wedges', 'Wedges', null),
    (46, 'Soludos Loafers', 'Loafers', null),
    (47, 'Do Bhai 400 Women Wedges', 'Wedges', null),
    (48, 'Tresmode 22827-3 Women Flats', 'Flats', null),
    (49, 'Zoot24 Mamas-3 Casual Shoes', 'Casual Shoes', null),
    (50, 'Liza Women Heels', 'Heels', null);

-- вывод: у 49 названий есть контрольная метка. pruto monk strap оставлен без нее.
-- вывод: набор сохранен в файле, поэтому повторный запуск не выбирает другие товары и не добавляет те же идентификаторы.

-- 3. сколько контрольных меток заполнено
select count(*) as total_examples,
       count(manual_type) as labeled_examples,
       count(*) - count(manual_type) as unclear_examples
from my_project.footwear_validation_reference;

-- вывод: в контрольной таблице 50 примеров: 49 с меткой и один спорный.
-- вывод: при подсчете совпадений спорный пример не включается в знаменатель.

-- 4. совпадения первой и итоговой версий
select
    count(*) as labeled_examples,
    sum(v.manual_type <=> p.type_v1) as matched_v1,
    sum(v.manual_type <=> p.type_v4) as matched_v4,
    round(100.0 * sum(v.manual_type <=> p.type_v4)
        / nullif(count(*), 0), 2) as agreement_v4_pct
from my_project.footwear_validation_reference v
left join (
    select product_name,
           max(predicted_type) as type_v1,
           max(predicted_type_v4) as type_v4
    from my_project.footwear_rules_v4
    group by product_name
) p on p.product_name = v.product_name
where v.manual_type is not null;

-- вывод: первая версия совпала с 42 из 49 контрольных меток. после доработки совпали все 49.
-- вывод: эти примеры использовались при изменении правил, поэтому результат не является независимой оценкой точности.

-- 5. разбор расхождений первой версии
select v.validation_id, v.product_name, v.manual_type,
       p.type_v1, p.type_v4
from my_project.footwear_validation_reference v
left join (
    select product_name,
           max(predicted_type) as type_v1,
           max(predicted_type_v4) as type_v4
    from my_project.footwear_rules_v4
    group by product_name
) p on p.product_name = v.product_name
where v.manual_type is not null
  and not (v.manual_type <=> p.type_v1)
order by v.validation_id;

-- вывод: у первой версии было семь расхождений: пять лоферов получили общую метку casual shoes,
-- вывод: а крем для обуви и clarks dunbar racer boat shoes остались без метки.

-- 6. сохранилась ли неоднозначность спорного примера
select v.product_name, v.comment, p.predicted_type_v4
from my_project.footwear_validation_reference v
left join (
    select product_name, max(predicted_type_v4) as predicted_type_v4
    from my_project.footwear_rules_v4
    group by product_name
) p on p.product_name = v.product_name
where v.manual_type is null;

-- вывод: pruto monk strap остается без подкатегории.
-- вывод: алгоритм не подставляет метку только ради увеличения охвата.
