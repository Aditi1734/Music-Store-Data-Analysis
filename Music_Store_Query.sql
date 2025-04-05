SELECT * FROM album

--SET 1 : EASY

--Q1 : Who is the senior most employee based on job title?

select * from employee
ORDER BY levels desc
limit 1

--Q2 : Which countries have the most Invoices?

select * from invoice

select count(*) as most_invoice_country, billing_country
from invoice
group by billing_country
order by most_invoice_country desc

--Q3 : What are top 3 values of total invoice?

select total from invoice
order by total desc
limit 3

--Q4 : Which city has the best customers? We would like to throw a promotional Music
--Festival in the city we made the most money. Write a query that returns one city that
--has the highest sum of invoice totals. Return both the city name & sum of all invoice
--totals.

select * from invoice

select SUM(total) as invoice_total, billing_city 
from invoice
group by billing_city
order by invoice_total desc

--Q5 : Who is the best customer? The customer who has spent the most money will be
--declared the best customer. Write a query that returns the person who has spent the
--most money.

select customer.customer_id, customer.first_name, customer.last_name, SUM(invoice.total) as total
from customer
JOIN invoice ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id
ORDER BY total desc
limit 1

--Q6 : What is the total revenue generated per month in a year?

SELECT 
    EXTRACT(YEAR FROM invoice_date) AS Year, 
    EXTRACT(MONTH FROM invoice_date) AS Month,
    SUM(total) AS Total_Revenue
FROM invoice
GROUP BY Year, Month
ORDER BY Year, Month;


--Q7 : What is the average purchase amount per customer?

SELECT 
    customer.customer_id, 
    customer.first_name || ' ' || customer.last_name AS customer_name, 
    AVG(invoice.total) AS avg_purchase_amount
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id, customer_name
ORDER BY customer_id;

--Q8 : 3.	Retrieve the most expensive track in the store.

SELECT track_id, name AS track_name, unit_price
FROM track
WHERE unit_price = (SELECT MAX(unit_price) FROM track);


--SET 2 : MODERATE

--Q1 : Write query to return the email, first name, last name, & Genre of all Rock Music
--listeners. Return your list ordered alphabetically by email starting with A.

select DISTINCT email, first_name, last_name
from customer
JOIN invoice on customer.customer_id = invoice.customer_id
JOIN invoice_line on invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN(
SELECT track_id FROM track
JOIN genre on track.genre_id = genre.genre_id
where genre.name LIKE 'Rock'
)
ORDER BY email;

--Q2 : Let's invite the artists who have written the most rock music in our dataset. Write a
--query that returns the Artist name and total track count of the top 10 rock bands.

SELECT artist.artist_id, artist.name, COUNT(artist.artist_id) AS number_of_songs
from TRACK
JOIN album on track.album_id = album.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN genre on track.genre_id = genre.genre_id
where genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY number_of_songs desc
limit 10;

--Q3 : Return all the track names that have a song length longer than the average song length.
--Return the Name and Milliseconds for each track. Order by the song length with the
--longest songs listed first.

SELECT name, milliseconds
FROM track
where milliseconds > (
SELECT AVG(milliseconds) AS avg_track_length
from track)
ORDER BY milliseconds desc;


--Q4 :  Find the second highest-selling track.

SELECT track_id, track_name, total_sales
FROM (
    SELECT t.track_id, t.name AS track_name, SUM(il.quantity) AS total_sales,
           RANK() OVER (ORDER BY SUM(il.quantity) DESC) AS sales_rank
    FROM invoice_line il
    JOIN track t ON il.track_id = t.track_id
    GROUP BY t.track_id, t.name
) ranked_tracks
WHERE sales_rank = 2;


--SET 3 : ADVANCE

--Q1 : Find how much amount spent by each customer on artists? Write a query to return
--customer name, artist name and total spent.

WITH best_selling_artist AS(
SELECT artist.artist_id AS artist_id, artist.name AS artist_name, 
SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
FROM invoice_line
JOIN track ON track.track_id = invoice_line.track_id
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
GROUP BY 1
ORDER BY 3 desc
LIMIT 1
) 
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, 
SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 desc;

--Q2 : We want to find out the most popular music Genre for each country. We determine the
--most popular genre as the genre with the highest amount of purchases. Write a query
--that returns each country along with the top Genre. For countries where the maximum
--number of purchases is shared return all Genres.

WITH popular_genre AS
(
SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id,
ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC ) AS RowNo
FROM invoice_line
JOIN invoice on invoice.invoice_id = invoice_line.invoice_id
JOIN customer on customer.customer_id = invoice.customer_id
JOIN track ON track.track_id = invoice_line.track_id
JOIN genre on track.genre_id = genre.genre_id
GROUP BY 2,3,4
ORDER BY 2 ASC, 1 DESC
)
SELECT * from popular_genre where RowNo <= 1

--Q3 : Write a query that determines the customer that has spent the most on music for each
--country. Write a query that returns the country along with the top customer and how
--much they spent. For countries where the top amount spent is shared, provide all
--customers who spent this amount.

WITH customer_with_country AS (
SELECT customer.customer_id, first_name, last_name, billing_country, SUM(total) AS total_spending,
ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC ) AS RowNo
from invoice
JOIN customer on customer.customer_id = invoice.customer_id
GROUP BY 1,2,3,4
ORDER BY 4 ASC, 5 DESC
)
SELECT * from customer_with_country where RowNo <= 1
