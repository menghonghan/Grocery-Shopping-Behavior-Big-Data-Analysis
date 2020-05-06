
create table trips_2004
select * from trips where year(TC_date)=2004;


#a. How many:
#1 Store shopping trips are recorded in your database?  
Select count(hh_id)
FROM trips where year(TC_date)=2004 ;

#2 Households appear in your database?
Select Count(Distinct(hh_id))
from households;

#3 Stores of different retailers appear in our data base?
SELECT Count(distinct(TC_retailer_code))
FROM trips where year(TC_date)=2004 ;

#4 Different products are recorded?
#i. Products per category and products per module
Select group_at_prod_id,Count(Prod_id)
from products
group by group_at_prod_id;

Select module_at_prod_id,Count(Prod_id)
from products
group by module_at_prod_id;

#ii. Plot the distribution of products per module and products per category
drop table if exists department;
create table department
select a.department_at_prod_id as department, products, module
from (Select department_at_prod_id, Count(distinct prod_id) as products
   from products
      group by department_at_prod_id) as a inner join 
      (select department_at_prod_id, count(distinct module_at_prod_id) as module
      from products
      group by department_at_prod_id) as b 
      on a.department_at_prod_id= b.department_at_prod_id;


#5 Transactions
#i. Total transactions and transactions realized under some kind of promotion.
SELECT Count(TC_id)
FROM purchases;

SELECT Count(TC_id)
from purchases
where deal_flag_at_TC_prod_id = 1;

## b(1)

drop table if exists t1;
create table t1
SELECT hh_id, TC_date , ROW_NUMBER() OVER (ORDER BY TC_date) as ID  FROM trips where year(TC_date)=2004  order by hh_id, TC_date;
    
drop table if exists t2;
create  table t2
	select *,  ID+1  as ID_2 from t1 order by hh_id, TC_date;


drop table if exists t3;
create  table t3
select   
          A.hh_id    as  hh_id_0 , 
          A.TC_date    as  TC_date_0 , 
		  B.hh_id    as  hh_id_1 , 
          B.TC_date    as  TC_date_1 , 
          datediff(B.TC_date   ,A.TC_date )/30 as TIME_WINDOW
from    
	t2 as A
	inner join  
	t1 as B
	on     A.ID_2 = B.ID;
select sum(TIME_WINDOW)
from
(select count(TIME_WINDOW) as TIME_WINDOW from t3 where TIME_WINDOW>3 
) a;

#b(2)
# hh_id's with shopping every month
CREATE  TABLE HH_once_month as
(SELECT *
FROM
(Select hh_id,Count(hh_id) AS Months
from 
(Select hh_id,month(TC_date)
from trips
group by hh_id,month(TC_date)) A
group by hh_id) B
WHERE months>11);

#Left joining trips data for those who shop once a month
Create  table HH_once_month_all as
(select A.*
from trips A
left join HH_once_month B
on A.hh_id=B.hh_id
where B.hh_id is not null);

#Calculating avg spent per household
DROP TABLE HH_AVG_SPENT;
CREATE TABLE HH_AVG_SPENT AS
select hh_id,sum(tc_total_spent)/12 AS AVG_SPENT
from HH_once_month_all
group by hh_id;
#having hh_id='9001556';

#Calculating average spent per retailer
DROP TABLE HH_AVG_SPENT_RETAILER;
CREATE TABLE HH_AVG_SPENT_RETAILER AS
select hh_id,tc_retailer_code,sum(tc_total_spent)/12 AS AVG_SPENT_PER_RETAILER
from HH_once_month_all
group by hh_id,tc_retailer_code;
#having hh_id='9001556';

#retailers percentage share
create table HH_PERCENTAGE_OF_SPENT AS
SELECT A.hh_id,A.tc_retailer_code,A.AVG_SPENT_PER_RETAILER,B.AVG_SPENT,(A.AVG_SPENT_PER_RETAILER/B.AVG_SPENT)*100 AS 'PERCENTAGE_OF_SPENT'
FROM HH_AVG_SPENT_RETAILER A
LEFT JOIN HH_AVG_SPENT B
ON A.HH_ID=B.HH_ID;

#one retailers with more than 80% share
select *
from HH_PERCENTAGE_OF_SPENT
where 'PERCENTAGE_of_spent'>=80;

#two retailers with more than 80% share
select A.HH_ID,A.TC_RETAILER_CODE,A.AVG_SPENT_PER_RETAILER,B.AVG_SPENT_PER_RETAILER,(A.AVG_SPENT_PER_RETAILER+B.AVG_SPENT_PER_RETAILER),
((A.AVG_SPENT_PER_RETAILER+B.AVG_SPENT_PER_RETAILER)/A.AVG_SPENT)*100
from HH_PERCENTAGE_OF_SPENT A
LEFT JOIN HH_PERCENTAGE_OF_SPENT B
ON A.HH_ID=B.HH_ID
AND A.TC_RETAILER_CODE<>B.TC_RETAILER_CODE
WHERE ((A.AVG_SPENT_PER_RETAILER+B.AVG_SPENT_PER_RETAILER)/A.AVG_SPENT)*100>80

#i. Are their demographics remarkably different? Are these people richer? Poorer?
SELECT A.HH_ID,B.HH_INCOME
FROM HH_2_RETAILERS_80 A
LEFT JOIN HOUSEHOLDS B
ON A.HH_ID=B.HH_ID;

#ii. What is the retailer that has more loyalists?
SELECT TC_RETAILER_CODE,SUM(TC_TOTAL_SPENT)
FROM TRIPS
GROUP BY TC_RETAILER_CODE
ORDER BY SUM(TC_TOTAL_SPENT) DESC
LIMIT 1;

#iii. Where do they live? Plot the distribution by state.
SELECT A.HH_ID,B.HH_STATE
FROM HH_2_RETAILERS_80 A 
LEFT JOIN HOUSEHOLDS B
ON A.HH_ID=B.HH_ID


#b(3)
#i
DROP  TABLE IF EXISTS Num_items;
CREATE TABLE Num_items
SELECT month, AVG(number) AS num_items
FROM (SELECT h.hh_id, MONTH(t.TC_date) AS month, AVG(p.quantity_at_TC_prod_id) AS number
  FROM trips_2004 t INNER JOIN households h on t.hh_id=h.hh_id
       INNER JOIN Purchases p on t.TC_id=p.TC_id	
  GROUP BY h.hh_id, MONTH(t.TC_date)) AS A 
GROUP BY month
ORDER BY month ASC;
#ii
DROP  TABLE IF EXISTS Num_trips;
CREATE TABLE Num_trips
SELECT month, AVG(number) AS num_trips
FROM (SELECT h.hh_id, MONTH(t.TC_date) AS month, COUNT(t.TC_id) AS number
  FROM trips_2004 t INNER JOIN households h on t.hh_id=h.hh_id
  GROUP BY h.hh_id, MONTH(t.TC_date)) AS B 
GROUP BY month
ORDER BY month ASC; 
#iii
DROP TABLE IF EXISTS t4;
CREATE  TABLE t4
SELECT hh_id, TC_date , ROW_NUMBER() OVER (ORDER BY hh_id, TC_date) as ID  
FROM trips_2004 
order by hh_id, TC_date;
    
DROP TABLE IF EXISTS t5;
CREATE  TABLE t5
SELECT *,  ID+1  AS ID_2 FROM t1 order by hh_id, TC_date;

DROP TABLE IF EXISTS t6;
CREATE  TABLE t6
SELECT A.hh_id as hh_id_0, A.TC_date as TC_date_0, B.hh_id as hh_id_1, B.TC_date as TC_date_1, 
datediff(B.TC_date, A.TC_date ) AS time_window
FROM  t5 AS A INNER JOIN t4 AS B ON  A.ID_2 = B.ID;

SELECT hh_id_0 as household, AVG(time_window) AS days
FROM t6
WHERE hh_id_0=hh_id_1
GROUP BY hh_id_0;


#3(1)

SELECT t.month, i.num_items, t.num_trips
FROM Num_trips t INNER JOIN  Num_items i on i.month=t.month;


#3(2)
select total_price_paid_at_TC_prod_id/quantity_at_TC_prod_id as avg_price_paid_per_item ,quantity_at_TC_prod_id as quantity_at_TC_prod_id from purchases;


#c(3)i

# join in table and get ratio
# note that this doesn't include ratio, where there are no private label products belonging to that product group. 
# This is not important in the question though as it asks for the groups with the highest fraction of private label goods.

drop table if exists categories_CTL_BR;
create  table categories_CTL_BR
select a.group_at_prod_id, a.count_pl, b.count_all, a.count_pl/b.count_all*100 as proportion
FROM 
	(select count(brand_at_prod_id) as count_pl, group_at_prod_id
from products
WHERE brand_at_prod_id = "CTL BR" 
group by group_at_prod_id
order by count(brand_at_prod_id)) AS a

INNER JOIN 
	(select count(brand_at_prod_id) as count_all, group_at_prod_id
from products
group by group_at_prod_id
order by count(brand_at_prod_id)) AS b

ON a.group_at_prod_id = b.group_at_prod_id;


#c(3)ii

## part c, ii
# join the tables needed with the relevant info



# get total monthly expenditure by month
drop table if exists pl_expend;
create table pl_expend
select sum(total_price_paid_at_TC_prod_id) as "all_prods", month(TC_date) as month1
FROM (select  b.TC_date, b.TC_id, a.brand_at_prod_id, a.prod_id, b.total_price_paid_at_TC_prod_id
FROM products as a INNER JOIN 
(select a.total_price_paid_at_TC_prod_id, a.prod_id, a.TC_id, b.TC_date
FROM purchases as a INNER JOIN trips_2004 as b on a.TC_id = b.TC_id) AS b 
ON a.prod_id = b.prod_id) as c
group by month(TC_date)
order by month(TC_date);


# get total expenditure by month on private labell branded products
drop table if exists private_expend;
create table private_expend
select sum(total_price_paid_at_TC_prod_id) as "pl_prods", month(TC_date) as month2
FROM (select  b.TC_date, b.TC_id, a.brand_at_prod_id, a.prod_id, b.total_price_paid_at_TC_prod_id
FROM products as a INNER JOIN 
(select a.total_price_paid_at_TC_prod_id, a.prod_id, a.TC_id, b.TC_date
FROM purchases as a INNER JOIN trips_2004 as b on a.TC_id = b.TC_id) AS b 
ON a.prod_id = b.prod_id) as c
WHERE brand_at_prod_id = "CTL BR"
group by month(TC_date)
order by month(TC_date);

drop table if exists CTL_BR_expenditure_share;
create table CTL_BR_expenditure_share
SELECT *, pl_prods/all_prods as share
FROM private_expend a inner join pl_expend b
     on a.month2=b.month1;

#c(3)iii
##low level income group
SELECT AVG(total_low), AVG(private_low), AVG(private_low)/AVG(total_low) AS percentage FROM
(SELECT Y1.TC_date, total_low, private_low, (private_low/total_low) AS percentage FROM
(SELECT TC_date, SUM(total_price_paid_at_TC_prod_id) AS total_low FROM
 (SELECT A1.hh_id, TC_date, TC_id FROM
  (SELECT hh_id, hh_income AS low_income FROM dta_at_hh WHERE hh_income BETWEEN 3 AND 15) AS A1
  INNER JOIN
  (SELECT hh_id, DATE_FORMAT(TC_date, '%Y-%m') AS TC_date, TC_id FROM dta_at_TC) AS A2
  ON A1.hh_id = A2.hh_id) AS B1
 INNER JOIN
  (SELECT TC_id, total_price_paid_at_TC_prod_id FROM dta_at_TC_upc) AS B2
 ON B1.TC_id = B2.TC_id
 GROUP BY TC_date) AS Y1
INNER JOIN
(SELECT TC_date, SUM(total_price_paid_at_TC_prod_id) AS private_low FROM
 (SELECT AA1.hh_id, TC_date, TC_id FROM
  (SELECT hh_id, hh_income AS low_income FROM dta_at_hh WHERE hh_income BETWEEN 3 AND 15) AS AA1
  INNER JOIN
  (SELECT hh_id, DATE_FORMAT(TC_date, '%Y-%m') AS TC_date, TC_id FROM dta_at_TC) AS AA2
  ON AA1.hh_id = AA2.hh_id) AS BB1
 INNER JOIN
 (SELECT TC_id, total_price_paid_at_TC_prod_id FROM
  (SELECT TC_id, prod_id, total_price_paid_at_TC_prod_id FROM dta_at_TC_upc) AS W2
  INNER JOIN
  (SELECT prod_id FROM dta_at_prod_id WHERE brand_at_prod_id REGEXP "CTL BR") AS W1
  ON W1.prod_id = W2.prod_id) AS BB2
 ON BB1.TC_id = BB2.TC_id
 GROUP BY TC_date) AS Y2
ON Y1.TC_date = Y2.TC_date) AS F1;
#middle level income group
SELECT AVG(total_mid), AVG(private_mid), AVG(private_mid)/AVG(total_mid) AS percentage FROM
(SELECT Y1.TC_date, total_mid, private_mid, (private_mid/total_mid) AS percentage FROM
(SELECT TC_date, SUM(total_price_paid_at_TC_prod_id) AS total_mid FROM
 (SELECT A1.hh_id, TC_date, TC_id FROM
  (SELECT hh_id, hh_income AS mid_income FROM dta_at_hh WHERE hh_income BETWEEN 16 AND 21) AS A1
  INNER JOIN
  (SELECT hh_id, DATE_FORMAT(TC_date, '%Y-%m') AS TC_date, TC_id FROM dta_at_TC) AS A2
  ON A1.hh_id = A2.hh_id) AS B1
 INNER JOIN
  (SELECT TC_id, total_price_paid_at_TC_prod_id FROM dta_at_TC_upc) AS B2
 ON B1.TC_id = B2.TC_id
 GROUP BY TC_date) AS Y1
INNER JOIN
(SELECT TC_date, SUM(total_price_paid_at_TC_prod_id) AS private_mid FROM
 (SELECT AA1.hh_id, TC_date, TC_id FROM
  (SELECT hh_id, hh_income AS mid_income FROM dta_at_hh WHERE hh_income BETWEEN 16 AND 21) AS AA1
  INNER JOIN
  (SELECT hh_id, DATE_FORMAT(TC_date, '%Y-%m') AS TC_date, TC_id FROM dta_at_TC) AS AA2
  ON AA1.hh_id = AA2.hh_id) AS BB1
 INNER JOIN
 (SELECT TC_id, total_price_paid_at_TC_prod_id FROM
  (SELECT TC_id, prod_id, total_price_paid_at_TC_prod_id FROM dta_at_TC_upc) AS W2
  INNER JOIN
  (SELECT prod_id FROM dta_at_prod_id WHERE brand_at_prod_id REGEXP "CTL BR") AS W1
  ON W1.prod_id = W2.prod_id) AS BB2
 ON BB1.TC_id = BB2.TC_id
 GROUP BY TC_date) AS Y2
ON Y1.TC_date = Y2.TC_date) AS F1;

#high level income group
SELECT AVG(total_high), AVG(private_high), AVG(private_high)/AVG(total_high) AS percentage FROM
(SELECT Y1.TC_date, total_high, private_high, (private_high/total_high) AS percentage FROM
(SELECT TC_date, SUM(total_price_paid_at_TC_prod_id) AS total_high FROM
 (SELECT A1.hh_id, TC_date, TC_id FROM
  (SELECT hh_id, hh_income AS high_income FROM dta_at_hh WHERE hh_income > 21) AS A1
  INNER JOIN
  (SELECT hh_id, DATE_FORMAT(TC_date, '%Y-%m') AS TC_date, TC_id FROM dta_at_TC) AS A2
  ON A1.hh_id = A2.hh_id) AS B1
 INNER JOIN
  (SELECT TC_id, total_price_paid_at_TC_prod_id FROM dta_at_TC_upc) AS B2
 ON B1.TC_id = B2.TC_id
 GROUP BY TC_date) AS Y1
INNER JOIN
(SELECT TC_date, SUM(total_price_paid_at_TC_prod_id) AS private_high FROM
 (SELECT AA1.hh_id, TC_date, TC_id FROM
  (SELECT hh_id, hh_income AS high_income FROM dta_at_hh WHERE hh_income > 21) AS AA1
  INNER JOIN
  (SELECT hh_id, DATE_FORMAT(TC_date, '%Y-%m') AS TC_date, TC_id FROM dta_at_TC) AS AA2
  ON AA1.hh_id = AA2.hh_id) AS BB1
 INNER JOIN
 (SELECT TC_id, total_price_paid_at_TC_prod_id FROM
  (SELECT TC_id, prod_id, total_price_paid_at_TC_prod_id FROM dta_at_TC_upc) AS W2
  INNER JOIN
  (SELECT prod_id FROM dta_at_prod_id WHERE brand_at_prod_id REGEXP "CTL BR") AS W1
  ON W1.prod_id = W2.prod_id) AS BB2
 ON BB1.TC_id = BB2.TC_id
 GROUP BY TC_date) AS Y2
ON Y1.TC_date = Y2.TC_date) AS F1;

