/*
تعداد دانشجویان حاضر
*/

SELECT
	COUNT(DISTINCT SS.StudentRef) Count
FROM
	Class C
	JOIN Session S ON S.ClassRef = C.Id
	JOIN SessionStudent SS ON SS.SessionRef = S.Id
WHERE
	StartDate IS NOT NULL
	AND
	EndDate IS NULL