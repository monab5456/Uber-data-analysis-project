-- Task IV: Uber bookings SQL analysis
-- Connect to the uber_database database. Source table: public.uber_bookings.

-- 1. Booking distribution by outcome.
WITH booking_groups AS (
    SELECT
        CASE
            WHEN "Booking Status" = 'Completed' THEN 'Completed'
            WHEN "Booking Status" IN ('Cancelled by Driver', 'Cancelled by Customer') THEN 'Cancelled'
            WHEN "Booking Status" IN ('Incomplete', 'No Driver Found') THEN 'Unfulfilled'
            ELSE 'Other / Unclassified'
        END AS booking_status_group
    FROM public.uber_bookings
)
SELECT
    booking_status_group,
    COUNT(*) AS total_bookings,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS percentage_of_bookings
FROM booking_groups
GROUP BY booking_status_group
ORDER BY total_bookings DESC;

-- 2. Total revenue from completed rides.
SELECT COALESCE(SUM("Booking Value"), 0) AS total_completed_revenue
FROM public.uber_bookings
WHERE "Booking Status" = 'Completed';

-- 3. Completed ride count and revenue by vehicle type.
SELECT
    "Vehicle Type" AS vehicle_type,
    COUNT(*) AS completed_ride_count,
    COALESCE(SUM("Booking Value"), 0) AS completed_ride_revenue
FROM public.uber_bookings
WHERE "Booking Status" = 'Completed'
GROUP BY "Vehicle Type"
ORDER BY completed_ride_revenue DESC;

-- 4. Customer and driver cancellations as a share of all bookings.
SELECT
    COUNT(*) AS total_bookings,
    COUNT(*) FILTER (WHERE "Booking Status" = 'Cancelled by Customer') AS customer_cancelled_bookings,
    ROUND(100.0 * COUNT(*) FILTER (WHERE "Booking Status" = 'Cancelled by Customer') / NULLIF(COUNT(*), 0), 2)
        AS customer_cancellation_percentage,
    COUNT(*) FILTER (WHERE "Booking Status" = 'Cancelled by Driver') AS driver_cancelled_bookings,
    ROUND(100.0 * COUNT(*) FILTER (WHERE "Booking Status" = 'Cancelled by Driver') / NULLIF(COUNT(*), 0), 2)
        AS driver_cancellation_percentage
FROM public.uber_bookings;

-- 5. Customer and driver ratings by vehicle type for completed rides.
SELECT
    "Vehicle Type" AS vehicle_type,
    COUNT("Customer Rating") AS customer_rating_count,
    ROUND(AVG("Customer Rating")::numeric, 2) AS average_customer_rating,
    COUNT("Driver Ratings") AS driver_rating_count,
    ROUND(AVG("Driver Ratings")::numeric, 2) AS average_driver_rating
FROM public.uber_bookings
WHERE "Booking Status" = 'Completed'
GROUP BY "Vehicle Type"
ORDER BY average_customer_rating DESC NULLS LAST, average_driver_rating DESC NULLS LAST;

-- 6. Payment method usage (exclude missing/not-applicable values).
SELECT
    "Payment Method" AS payment_method,
    COUNT(*) AS booking_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS percentage_of_reported_payment_methods
FROM public.uber_bookings
WHERE "Payment Method" IS NOT NULL
  AND "Payment Method" <> 'Not Applicable'
GROUP BY "Payment Method"
ORDER BY booking_count DESC;

-- 7. Pickup demand by hour of day. Use DateTime, which the loader stores as a timestamp.
SELECT
    "Pickup Location" AS pickup_location,
    EXTRACT(HOUR FROM "DateTime")::integer AS hour_of_day,
    COUNT(*) AS total_bookings
FROM public.uber_bookings
GROUP BY "Pickup Location", EXTRACT(HOUR FROM "DateTime")
ORDER BY total_bookings DESC, pickup_location, hour_of_day;

-- 8. Busiest weekday (include ties).
WITH weekday_counts AS (
    SELECT
        EXTRACT(ISODOW FROM "DateTime")::integer AS weekday_number,
        TO_CHAR("DateTime", 'FMDay') AS weekday_name,
        COUNT(*) AS total_bookings
    FROM public.uber_bookings
    GROUP BY EXTRACT(ISODOW FROM "DateTime"), TO_CHAR("DateTime", 'FMDay')
)
SELECT weekday_name, total_bookings
FROM weekday_counts
WHERE total_bookings = (SELECT MAX(total_bookings) FROM weekday_counts)
ORDER BY weekday_number;

-- 9. Busiest hour (include ties).
WITH hour_counts AS (
    SELECT EXTRACT(HOUR FROM "DateTime")::integer AS hour_of_day, COUNT(*) AS total_bookings
    FROM public.uber_bookings
    GROUP BY EXTRACT(HOUR FROM "DateTime")
)
SELECT hour_of_day, total_bookings
FROM hour_counts
WHERE total_bookings = (SELECT MAX(total_bookings) FROM hour_counts)
ORDER BY hour_of_day;

-- 10. Top 10 highest-demand pickup areas and their completion rates.
WITH pickup_area_stats AS (
    SELECT
        "Pickup Location" AS pickup_location,
        COUNT(*) AS total_bookings,
        COUNT(*) FILTER (WHERE "Booking Status" = 'Completed') AS completed_bookings,
        ROUND(100.0 * COUNT(*) FILTER (WHERE "Booking Status" = 'Completed') / NULLIF(COUNT(*), 0), 2)
            AS completion_rate_percentage
    FROM public.uber_bookings
    GROUP BY "Pickup Location"
),
top_10_areas AS (
    SELECT *
    FROM pickup_area_stats
    ORDER BY total_bookings DESC, pickup_location
    LIMIT 10
)
SELECT *
FROM top_10_areas
ORDER BY completion_rate_percentage ASC, total_bookings DESC;

-- 11. Booking demand and completion rate by vehicle type.
SELECT
    "Vehicle Type" AS vehicle_type,
    COUNT(*) AS total_bookings,
    COUNT(*) FILTER (WHERE "Booking Status" = 'Completed') AS completed_bookings,
    ROUND(100.0 * COUNT(*) FILTER (WHERE "Booking Status" = 'Completed') / NULLIF(COUNT(*), 0), 2)
        AS completion_rate_percentage
FROM public.uber_bookings
GROUP BY "Vehicle Type"
ORDER BY total_bookings DESC, completion_rate_percentage ASC;
