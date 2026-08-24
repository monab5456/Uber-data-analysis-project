-- Distribution of bookings across completed, cancelled and unfulfilled rides.
SELECT (CASE WHEN "Booking Status" = 'Completed' THEN 'Completed'
			WHEN "Booking Status" IN ('Cancelled by Driver','Cancelled by Customer') THEN 'Cancelled'
			ELSE 'Unfulfilled' END) AS Booking_status,
count(*) AS total_booking,
round(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),2) AS percentofstatus FROM uber_data_cleaned 
group by Booking_status ORDER by total_booking DESC;

-- Total revenue of rides completed successfully.
SELECT SUM("Booking Value") AS Total_revenue FROM uber_data_cleaned 
WHERE "Booking Status" = 'Completed';

-- Total revenue by vehicle type.
SELECT "Vehicle Type", SUM("Booking Value") AS revenue FROM uber_data_cleaned 
GROUP BY "Vehicle Type" ORDER BY SUM("Booking Value") DESC;

-- Percentage of bookings are cancelled by customers and drivers?
SELECT 
ROUND((100.0*SUM(CASE WHEN "Booking Status" = 'Cancelled by Customer' THEN 1 ELSE 0 END))/COUNT("Booking ID"),2) AS percentge_ride_cancelled_customer,
ROUND((100.0*SUM(CASE WHEN "Booking Status" = 'Cancelled by Driver' THEN 1 ELSE 0 END))/COUNT("Booking ID"),2) AS percentge_ride_cancelled_driver
FROM uber_data_cleaned

-- Which vehicle types have the highest customer and driver satisfaction?
SELECT "Vehicle Type", AVG("Customer Rating") AS avg_customer_rating,
AVG("Driver Ratings") AS avg_Driver_rating
FROM uber_data_cleaned GROUP BY "Vehicle Type";

-- Payment method used by customer.
select "Payment Method",count(*) as total_count,
ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER(),2) AS percentage
from uber_data_cleaned where "Payment Method" != 'Not Applicable' group by "Payment Method" ORDER by total_count desc;

-- Demand of ride experienced by pickup area in each hour of day.
SELECT "Pickup Location", extract(hour from "Time") AS Hour, count("Booking ID") AS Total_Booking
FROM uber_data_cleaned GROUP BY "Pickup Location", extract(hour from "Time") ORDER BY count("Booking ID") DESC;

-- Busiest day of a week:
SELECT TO_char("Date",'day') AS Busiest_day_of_week, count("Booking ID") AS total_booking FROM uber_data_cleaned 
GROUP BY TO_char("Date",'day') ORDER BY count("Booking ID") DESC LIMIT 1;

-- Busiest hour of a day:
SELECT extract(hour from "Time") AS Busiest_hour_of_day, count("Booking ID") AS total_booking FROM uber_data_cleaned 
GROUP BY extract(hour from "Time") ORDER BY count("Booking ID") DESC LIMIT 1;

--  Pickup areas have high demand but low completion rate.
WITH area_stats AS (
SELECT "Pickup Location",COUNT("Booking ID") AS total_bookings,
SUM(CASE WHEN "Booking Status" = 'Completed' THEN 1 ELSE 0 END) AS completed_bookings
FROM uber_data_cleaned GROUP BY "Pickup Location"
)
SELECT "Pickup Location",
ROUND(100.0*completed_bookings/total_bookings, 2) AS completion_rate
FROM area_stats
WHERE total_bookings > (SELECT AVG(total_bookings) FROM area_stats)
ORDER BY completion_rate ASC
LIMIT 10;

-- Vehicle types have high demand but low completion rate.
WITH vechicle AS (
SELECT "Vehicle Type",COUNT("Booking ID") AS total_bookings,
SUM(CASE WHEN "Booking Status" = 'Completed' THEN 1 ELSE 0 END) AS completed_bookings
FROM uber_data_cleaned GROUP BY "Vehicle Type"
)
SELECT "Vehicle Type",
ROUND(100.0*completed_bookings/total_bookings, 2) AS completion_rate
FROM vechicle
ORDER BY completion_rate ASC
LIMIT 10;
