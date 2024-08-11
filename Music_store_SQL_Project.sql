                             -- PROJECT --

Create database project01;
use project01;

select * from album;
select * from artist;
select * from customer;
select * from employee;
select * from genre;
select * from invoice;
select * from invoice_line;
select * from media_type;
select * from playlist_track;
select * from track;
select * from playlist;

-- List all album titles and their respective artists.

SELECT distinct al.title,ar.name
FROM artist ar 
JOIN album al 
ON ar.artist_id=al.artist_id;


-- Show all playlists with their names.

SELECT distinct  name 
FROM playlist;

-- List the names of all tracks in a specific playlist (e.g., PlaylistId = 1).

SELECT pt.playlist_id,t.name 
FROM track t
JOIN playlist_track pt
ON pt.track_id=t.track_id
WHERE pt.playlist_id;

-- Retrieve all employees and the names of the employees they report to.

SELECT e1.employee_id,
       concat_ws(' ',e1.first_name,e1.last_name) as Employee_name,
       e2.employee_id,concat(e2.first_name,' ',e2.last_name) as "Employee Reports to"
FROM employee e1 
LEFT JOIN employee e2
ON e1.reports_to=e2.employee_id;

-- Find all customers in a specific city (e.g., 'Boston,Chicago...').

SELECT first_name ,last_name
FROM customer 
WHERE city="Boston";

-- Calculate the total number of tracks in each genre.

SELECT t.genre_id,
       g.name,
       sum(t.track_id) as "No of tracks"
FROM track t 
JOIN genre g
ON g.genre_id=t.genre_id
GROUP BY g.genre_id,g.name ;

-- Find the total amount spent by each customer.

SELECT c.customer_id,
       c.first_name,
       sum(i.total) as "Total Amount"
FROM customer c 
JOIN invoice i
ON c.customer_id=i.customer_id
GROUP BY  i.customer_id,c.first_name;

-- List the names of customers who have purchased a specific track (e.g., TrackId = 1,2,3,4...).

SELECT c.first_name,
       c.last_name,
       il.track_id
FROM customer c 
JOIN invoice i
ON c.customer_id=i.customer_id 
JOIN invoice_line il
ON il.invoice_id=i.invoice_id
WHERE il.track_id=2;

-- Find the most expensive track and its details.

SELECT  *
FROM  track
ORDER BY unit_price desc
LIMIT 1;

-- Retrieve the list of tracks that belong to the 'Rock' genre along with their album names.

select t.track_id "Track Id",t.name "Track Name"
from album b
join track t on b.﻿album_id=t.album_id
join genre g on g.genre_id=t.genre_id
where g.name='Rock';

-- Calculate the total sales amount for each genre.

SELECT g.name Genre_name,
       sum(il.unit_price*quantity) as "Total_sales"
FROM invoice_line il 
JOIN track t 
ON t.track_id=il.track_id 
JOIN genre g 
ON t.genre_id=g.genre_id
GROUP BY g.name;

-- List the employees along with the total number of invoices they have processed.

SELECT e.employee_id,
       e.first_name,
       count(invoice_id) as No_of_invoices 
FROM employee e
JOIN customer c 
ON c.support_rep_id=e.employee_id
JOIN invoice i 
ON i.customer_id=c.customer_id
GROUP BY e.employee_id,e.first_name;

-- Identify the most popular track (the track that appears in the most playlists).

WITH popular_track as (
	   SELECT t.track_id,
              t.name,
			  count(pt.playlist_id) CountOfPlaylist
       FROM track t 
       JOIN playlist_track pt
       ON t.track_id=pt.track_id
       GROUP BY t.track_id,t.name
       ORDER BY count(pt.playlist_id) desc)

SELECT  p.track_id,
        p.name "TrackName",
        p.countofPlaylist
FROM popular_track p
WHERE p.countOfPlaylist = (
                   SELECT max(countOfPlaylist) 
                   FROM popular_track);

-- Get the total number of customers and the total sales for each country.

SELECT  c.country,
        sum(c.customer_id) "No of Customer",
        sum(i.total) "Total_sales"
FROM customer c 
JOIN invoice i
ON i.customer_id=c.customer_id
GROUP BY c.country;

-- Identify tracks that have never been purchased.

SELECT track_id,
       name
FROM track 
WHERE track_id NOT IN (
                   SELECT track_id 
                   FROM invoice_line
                   );

-- Calculate the running total of sales for each customer.

SELECT c.first_name,
       c.last_name,
       i.invoice_id,
       i.invoice_date,
       sum(i.total) over(partition by c.customer_id order by i.invoice_date) "Running_sales"
FROM customer c 
INNER JOIN  invoice i 
ON i.customer_id=c.customer_id ;

-- Find the second most popular genre by the number of tracks sold. 

WITH GenreTrack as (
	        SELECT g.genre_id,
		           g.name,
		           count(i.track_id) as "No_of_Tracks_Sold" 
            FROM genre g 
            JOIN track t
            ON t.genre_id=g.genre_id
            JOIN  invoice_line i 
            ON i.track_id=t.track_id
            GROUP BY  t.genre_id,g.name
					),
       GenreTrackRank as (
                SELECT *,
                       row_number() over (order by No_of_tracks_Sold desc) as "rank_genre" 
                FROM GenreTrack
                         )
SELECT * 
FROM GenreTrackRank
WHERE rank_genre=2;


-- Average Sales per Genre by Month
-- The genres that had an average sales amount higher than the overall average sales amount for any genre in any month

CREATE VIEW Average_sales as (
			SELECT g.genre_id,
                   g.name,
                   year(i.invoice_date),
                   month(i.invoice_date),
                   avg(il.unit_price*il.quantity) as avgSales
            FROM invoice_line il
            JOIN track t 
            ON t.track_id=il.track_id
            JOIN genre g 
            ON g.genre_id=t.genre_id
            JOIN invoice i on i.invoice_id=il.invoice_id
            GROUP BY 1,2,3,4
							);
SELECT * 
FROM Average_sales
WHERE avgsales > (
          SELECT avg(unit_price*quantity) AS AverageSales 
          FROM invoice_line
                 );

-- Customers with Increasing Purchase Amounts

	WITH previous_total as(
			SELECT c.customer_id,
				   c.first_name,
				   c.address,
				   c.city,
				   c.email,
				   i.invoice_date,
				   i.total, 
			lag(i.total) over(partition by c.customer_id order by i.invoice_date) "PreviousTotal",
			lag(i.total,2) over(partition by c.customer_id order by i.invoice_date) "TwodaysbeforePurchasetotal" 
			FROM invoice i
			JOIN customer c 
			ON c.customer_id=i.customer_id)
			
	SELECT customer_id,invoice_date,total
	FROM previous_total 
	WHERE total> PreviousTotal and total>Twodaysbeforepurchasetotal;

-- Top 5 Customers by Yearly Spending Growth

CREATE VIEW YearWise_Total as (
		SELECT c.customer_id,
               c.first_name,
               c.city,
               year(i.invoice_date) year,
               sum(i.total) as SumOfTotal
		FROM customer c 
        JOIN invoice i 
        ON i.customer_id=c.customer_id
		GROUP BY c.customer_id,c.first_name,c.city,year(i.invoice_date)
        ORDER BY c.customer_id
                              );
CREATE VIEW  Year_Diff as (
        SELECT * ,
               lag(SumOfTotal) over(partition by customer_id order by year) as PreviousYearTotal,
	           round((SumOfTotal-(lag(SumOfTotal) over(partition by customer_id order by year)))/
                         (lag(SumOfTotal) over(partition by customer_id order by year)),1) as GrowthRate
        FROM YearWiseTotal
                          );
SELECT customer_id,
       first_name,
       city,
       year,
       GrowthRate
FROM YearDiff
WHERE GrowthRate is NOT NULL and GrowthRate>0
ORDER BY GrowthRate DESC
LIMIT 5;

-- Find Albums with No Sales in the Last Year

SELECT *
FROM album b
WHERE not exists(
            SELECT 1
            FROM track t 
			JOIN invoice_line il 
            ON il.track_id=t.track_id
            JOIN invoice i 
            ON i.invoice_id=il.invoice_id
            WHERE b.﻿album_id=t.album_id);
