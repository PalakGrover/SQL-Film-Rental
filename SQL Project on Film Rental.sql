select * from address;
show tables;
use film_rental;

-- Q1: What is the total revenue generated from all rentals in the database?

-- Approach 1
select sum(p.amount)
from payment p 
join
rental q on p.rental_id = q.rental_id
;

-- Approach 2
select sum(p.amount)
from payment p 
where rental_id in
(select q.rental_id 
from rental q
where p.rental_id = q.rental_id);

-- Q2: How many rentals were made in each month_name? 
select * from category;
select * from rental;
select * from film;

-- Approach 1
select distinct monthname(rental_date), count(rental_id) as monthly_rental_made
from rental
group by 1
order by 2;

-- Q3: What is the rental rate of the film with the longest title in the database?
select title, LENGTH (title)  as longest_title, rental_rate
from film
group by 1, 3
order by longest_title desc 
limit 1;

-- Q4: What is the average rental rate for films that were taken from the last 30 days from the date("2005-05-05 22:04:30")?

-- Approach 1 - Using transitive relationship from backward, rental -> inventory -> store -> film
select avg(rental_rate)
from rental r
join inventory i on r.inventory_id = i.inventory_id
join store s on i.store_id = s.store_id
join film f on i.film_id = f.film_id
where r.rental_date >= date("2005-05-05 22:04:30") and rental_date <= date("2005-06-05 22:04:30");

-- Approach 2 - Joins in One Go
select avg(rental_rate)
from inventory i join rental r join film f 
on r.inventory_id = i.inventory_id
and i.film_id = f.film_id
where r.rental_date between "2005-05-05 22:04:30" and "2005-06-05 22:04:30";

-- Approach 3 -  Getting a direct relationship of inventory to film using inventory _id to connect to rental toreceive the 30 days diff between rental abd return date
select avg(f.rental_rate)
from film f
join inventory i on i.film_id = f.film_id
join rental r on i.inventory_id = r.inventory_id
where r.rental_date >= date("2005-05-05 22:04:30") and rental_date <= date("2005-06-05 22:04:30");

-- Q5: What is the most popular category of films in terms of the number of rentals?
select count(distinct rental_id) as max, c.name
from category c
join film_category fc  on c.category_id = fc.category_id
join film f on fc.film_id = f.film_id
join inventory i on f.film_id = i.film_id
join rental r on i.inventory_id = r.inventory_id
group by 2 order by max desc limit 1;

-- Actions taken to get the result
select category_name
from film_rental.`category`
where category_id = any(select category_id
from film_rental.`film` 
where film_id = any(select film_id
from film_rental.`film_category`));

select count(fc.film_id) as fc, c.category_id,  count(c.category_name) as cn
from film_rental.`film_category` fc, film_rental.`category` c
where c.category_id = fc.category_id
and category_name = 'action'
group by 2;

Q6: Find the longest movie duration from the list of films that have not been rented by any customer? 
-- Approach 1 - Using only multiple joins
select max(f.length) 
from film f, store s
join inventory i on s.store_id = i.store_id
join rental r on i.inventory_id = r.inventory_id
where r.rental_id <> f.film_id;

-- Approach 2 - Using "Row Number" over film_id which has the highest_movie_duration
select max(length) as longest_movie_duration
from
(select f.film_id, length, row_number() over (partition by f.film_id order by length desc) as rn
from film f, store s
join inventory i on s.store_id = i.store_id
join rental r on i.inventory_id = r.inventory_id
join customer c on r.customer_id = c.customer_id
where r.rental_id <> r.customer_id
)subquery
where rn=1;

use film_rental;
-- Q7: What is the average rental rate for films, broken down by category? 
select avg(rental_rate) as monthly_rate
from film f
join film_category fc on f.film_id = fc.film_id
join category c on fc.category_id = c.category_id
where f.film_id <> fc.category_id;

-- Q8: What is the total revenue generated from rentals for each actor in the database

-- s-- elect sum(rental_rate) as revenue_for_actors
-- from film f
-- join inventory i on f.film_id = i.film_id
-- join rental r on i.inventory_id = r.inventory_id
-- join film_actor fa on f.film_id = fa.film_id
-- join actor a on fa.actor_id = a.actor_id;
-- Using Joins 
select a.actor_id, a.first_name, a.last_name, sum(p.amount) as total_revenue_generated_on_rentals
from actor a
join film_actor fa on a.actor_id  = fa.actor_id
join inventory i on fa.film_id = i.film_id
join rental r on i.inventory_id = r.inventory_id
join payment p on r.rental_id = p.rental_id
group by 1,2,3
order by 4 desc;

-- Using suqbuery
select 
a.actor_id,
a.first_name,
a.last_name,
(select sum(p.amount)
	from payment p 
	join rental r on p.rental_id = r.rental_id
	join inventory i on r.inventory_id = i.inventory_id
	join film_actor fa on i.film_id = fa.film_id
    where a.actor_id = fa.actor_id) as total_revenue_generated_by_rentals
from actor a
order by total_revenue_generated_by_rentals desc;

-- Q9: Show all the actresses who worked in a film having a "Wrestler" in description. 

    select 
    substring(a.first_name, 1) AS actress_name,
    case
        when substring_index(a.first_name, ' ', 1) like '%a' then 'Female'
        when substring_index(a.first_name, ' ', 1) like '%e' then 'Female'
	    when substring_index(a.first_name, ' ', 1) like '%i' then 'Female'
        when substring_index(a.first_name, ' ', 1) like '%y' then 'Female'
        else " " 
    end as gender
from
    actor a
        join
    film_actor fa on a.actor_id = fa.actor_id
        join
    film f on fa.film_id = f.film_id
where
    description like '%wrestler%';
    
    -- Q10: Which customers have rented the same film more than once? 
select c.customer_id, concat_ws(c.first_name, c.last_name) as customer_name
from customer c
join rental r join inventory i join film f
on r.customer_id = c.customer_id 
and f.film_id = i.film_id
group by 1
having count(rental_id) > 1; 

-- Q11: How many films in the comedy category have a rental rate higher than the average rental rate? 
select count(f.film_id)
from film f
join film_category fc on f.film_id = fc.film_id
join category c on fc.category_id = c.category_id
where f.rental_rate = any(select g.film_id from film g
where c.name = '%Comedy%' 
group by 1
having  avg(g.rental_rate) > f.rental_rate)
;

-- Q12: 12.	Which films have been rented the most by customers living in each city? 
select
    ct.city,
    COUNT(r.rental_id) as rental_count
from
    rental r 
	join inventory i on r.inventory_id = i.inventory_id 
    join film f on i.film_id = f.film_id 
    join customer on r.customer_id = c.customer_id 
    join city ct  on c.last_update = ct.last_update
    join (
        select 
            city ct, 
            MAX(rental_count) as max_rental_count
        from (
            SELECT 
                ct.city, 
                f.title, 
                COUNT(r.rental_id) AS rental_count
            FROM 
                rental r 
                JOIN inventory i ON r.inventory_id = i.inventory_id 
                JOIN film f ON i.film_id = f.film_id 
                JOIN customer c ON r.customer_id = c.customer_id 
                join city ct  on c.last_update = ct.last_update
            GROUP BY 
                ct.city, 
                f.title
        ) AS rental_counts_by_city_and_film
        GROUP BY 
            city
    ) AS max_rental_counts_by_city on ct.city = ct.max_rental_counts_by_city
        AND rental_count = max_rental_counts_by_city.max_rental_count
GROUP BY 
    ct.city, 
    f.title;

-- Q13: Create a View for the total revenue generated by each staff member, broken down by store city with country name? (4 Marks)
create view staff_rev_by_country as
select 
    CONCAT_WS(', ', c.city, co.country) as loc_store, 
    CONCAT_WS(' ', s.first_name, s.last_name) AS staff_name, 
    SUM(p.amount) as total_revenue
from
    store st
    join address a on st.address_id = a.address_id
    join city c on a.city_id = c.city_id
    join country co on c.country_id = co.country_id
    join staff s on st.store_id = s.store_id
    join payment p on s.staff_id = p.staff_id
group by 
    loc_store, 
    staff_name;
    
-- Q15: Create a view based on rental information consisting of visiting_day, customer_name, title of film, no_of_rental_days, amount paid by the customer along with percentage of customer spending.
create view rental_smmarised_view as
select 
    r.rental_date as visiting_day,
    CONCAT_WS(' ', c.first_name, c.last_name) as customer_name,
    f.title as film_title,
    f.rental_duration as no_of_rental_days,
    p.amount as amount_paid,
    (p.amount / p.amount) * 100 as percentage_spent
from 
    rental r 
    join inventory i on r.inventory_id = i.inventory_id 
     join film f on i.film_id = f.film_id 
    join customer c on r.customer_id = c.customer_id 
	join payment p on r.rental_id = p.rental_id;
    
    -- Q16: Display the customers who paid 50% of their total rental costs within one day.
    select
    concat_ws(' ', c.first_name, c.last_name) as customer_name,
    round(sum(p.amount), 2) as total_rental_cost,
    sum(datediff(p.payment_date, r.rental_date)) as rental_days,
    round((sum(p.amount) / f.rental_rate) * 100, 2) as percentage_spent
from 
    rental r 
    join inventory i on r.inventory_id = i.inventory_id 
    join film f on i.film_id = f.film_id 
    join customer c on r.customer_id = c.customer_id 
    join payment p on r.rental_id = p.rental_id 
group by 
    r.customer_id 
having
    sum(p.amount) >= (f.rental_rate / 2) and sum(datediff(p.payment_date, r.rental_date)) = 0;
    
select c.customer_id, c.first_name, c.last_name 
from customer c
join rental r on c.customer_id = r.customer_id
join payment p on r.rental_id = p.rental_id
join inventory i on r.inventory_id  = r.inventory_id
join film f on i.film_id = f.film_id
WHERE p.amount >= (f.rental_rate) * 0.5
AND p.payment_date = r.rental_date
  AND datediff(p.payment_date, r.rental_date) = 0;
  
  SELECT c.customer_id, c.first_name, c.last_name 
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
JOIN payment p ON r.rental_id = p.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
WHERE p.payment_date - r.rental_date = 0
group by 1
having p.amount >= (f.rental_rate * f.rental_duration) * 0.5;

select r.customer_id, c.first_name, c.last_name
from rental r
join payment p ON r.rental_id = p.rental_id
join inventory i on r.inventory_id = i.inventory_id
join film f on i.film_id = f.film_id
WHERE p.payment_date = r.rental_date + INTERVAL 1 DAY
group by 1
having sum(f.rental_rate  * f.rental_duration) * 0.5 <= sum(p.amount);

select c.customer_id
from customer c
join rental r on r.customer_id = c.customer_id
join payment p on r.rental_id = p.rental_id
where p.payment_date = r.rental_date + INTERVAL 1 DAY
group by 1
having sum(f.rental_rate  * f.rental_duration) * 0.5 <= p.amount;

--   AND payments.payment_date = DATE_ADD(rentals.rental_date, INTERVAL 1 DAY);
--      SELECT 
--     CONCAT_WS(' ', c.first_name, c.last_name) AS customer_name,
--     ROUND(SUM(p.amount), 2) AS total_rental_cost,
--     SUM(DATEDIFF(p.payment_date, r.rental_date)) AS rental_days,
--     ROUND((SUM(p.amount) / (SELECT SUM(amount) FROM payment WHERE r.customer_id = c.customer_id)) * 100, 2) AS percentage_spent
-- FROM 
--     rental r 
--     JOIN inventory i ON r.inventory_id = i.inventory_id 
--     JOIN film f ON i.film_id = f.film_id 
--     JOIN customer c ON r.customer_id = c.customer_id 
--     JOIN payment p ON r.rental_id = p.rental_id 
-- GROUP BY 
--     r.customer_id 
-- HAVING 
--     SUM(p.amount) >= ((SELECT SUM(amount) FROM payment WHERE customer_id = c.customer_id) / 2) AND SUM(DATEDIFF(p.payment_date, r.rental_date)) = 0;