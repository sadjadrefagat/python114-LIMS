/*
میانگین زمان برگزاری کلاس در یک ماه اخیر
*/

SELECT
	AVG(DATEDIFF(MINUTE, CAST(StartTime AS TIME), CAST(EndTime AS TIME)))
FROM
	Session S
WHERE
	S.Date >= '1405/04/01'