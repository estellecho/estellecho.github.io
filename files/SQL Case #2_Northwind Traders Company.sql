---[1] Entertainer Details
--Q1. Show a list of entertainers based in ‘Bellevue,’ ‘Redmond,’ or ‘Woodinville’ who do not have a registered email address. Include their stage name, phone number, and city.
SELECT entstagename, entphonenumber, entcity
FROM entertainers
WHERE entcity IN ('Bellevue', 'Redmond', 'Woodinville') 
  AND entemailaddress IS NULL;

--Q2. List entertainers who have either never been booked or do not have a webpage or email address. Sort by entertainer ID in ascending order.
SELECT entertainerid, entstagename
FROM entertainers
WHERE NOT EXISTS (
    SELECT 1
    FROM engagements
    WHERE entertainers.entertainerid = engagements.entertainerid
)
OR entwebpage IS NULL
OR entemailaddress IS NULL
ORDER BY entertainerid;

--Q3. List entertainers who specialize in a specific musical style (e.g., Jazz or Pop) but have not performed any engagements in the past two years. Include their stage name, musical style, and last engagement date.
SELECT ent.entstagename, ms.stylename, MAX(eng.enddate) AS last_engagement_date
FROM entertainers AS ent
JOIN entertainer_styles AS es ON ent.entertainerid = es.entertainerid
JOIN musical_styles AS ms ON es.styleid = ms.styleid
LEFT JOIN engagements AS eng ON ent.entertainerid = eng.entertainerid
WHERE eng.enddate IS NULL OR eng.enddate < CURRENT_DATE - INTERVAL '2 years'
GROUP BY ent.entstagename, ms.stylename
ORDER BY last_engagement_date ASC;

--Q4. Identify entertainers who are managed by more than one agent. Provide their stage name, agent names, and contact details.
SELECT DISTINCT
    ent.entstagename AS entertainer_stage_name,
    agt.agtfirstname AS agent_first_name,
    agt.agtlastname AS agent_last_name,
    agt.agtphonenumber AS agent_contact
FROM entertainers AS ent
JOIN engagements AS eng ON ent.entertainerid = eng.entertainerid
JOIN agents AS agt ON eng.agentid = agt.agentid
WHERE ent.entertainerid IN (
    SELECT entertainerid
    FROM engagements
    GROUP BY entertainerid
    HAVING COUNT(DISTINCT agentid) > 1
)
ORDER BY ent.entstagename, agt.agtfirstname;

---[2] Engagement Analysis
--Q5. Summarize engagements by month for the year 2018, including the total number of engagements and average contract price. Sort by month in ascending order.
SELECT 
    EXTRACT(MONTH FROM eng.startdate) AS engagement_month,
    COUNT(*) AS total_engagements,
    ROUND(AVG(eng.contractprice),2) AS average_contract_price
FROM 
    engagements AS eng
WHERE 
    EXTRACT(YEAR FROM eng.startdate) = 2018
GROUP BY 
    engagement_month
ORDER BY 
    engagement_month ASC;
	
--Q6. Identify the top 5 entertainers with the longest cumulative engagement durations (in days) for the year 2017. For each entertainer, include their stage name, total number of engagements, cumulative engagement days, and average contract price. Also, categorize them based on their engagement frequency:
-- "High Frequency" if they had 10 or more engagements.
-- "Moderate Frequency" if they had 5 to 9 engagements.
-- "Low Frequency" if they had fewer than 5 engagements.
-- Sort the results by cumulative engagement days in descending order.

SELECT 
    ent.EntStageName AS StageName,
    COUNT(eng.EngagementNumber) AS TotalEngagements,
    SUM((eng.EndDate - eng.StartDate) + 1) AS CumulativeEngagementDays,
  	ROUND(AVG(eng.ContractPrice),0) AS AverageContractPrice,
    CASE 
        WHEN COUNT(eng.EngagementNumber) >= 10 THEN 'High Frequency'
        WHEN COUNT(eng.EngagementNumber) BETWEEN 5 AND 9 THEN 'Moderate Frequency'
        ELSE 'Low Frequency'
    END AS EngagementFrequency
FROM Entertainers AS ent
JOIN Engagements AS eng ON ent.EntertainerID = eng.EntertainerID
WHERE EXTRACT(YEAR FROM eng.StartDate) = 2017
GROUP BY ent.EntStageName
ORDER BY CumulativeEngagementDays DESC
LIMIT 5;

---[3] Customer Engagements
--Q7. Identify the top 5 customers with the highest total engagement spending in 2017. Include customer name, total spending, and number of engagements booked.
SELECT 
    CONCAT(cus.CustFirstName, ' ', cus.CustLastName) AS CustomerName,
    SUM(eng.ContractPrice) AS TotalSpending,
    COUNT(eng.EngagementNumber) AS EngagementsBooked
FROM Customers AS cus
JOIN Engagements AS eng ON cus.CustomerID = eng.CustomerID
WHERE EXTRACT(YEAR FROM eng.StartDate) = 2017
GROUP BY cus.CustomerID
ORDER BY TotalSpending DESC
LIMIT 5;

--Q8. List customers who booked engagements with entertainers in more than three different musical styles. Include customer name, total engagement count, and musical styles booked.
SELECT 
    CONCAT(cus.CustFirstName, ' ', cus.CustLastName) AS CustomerName,
    COUNT(eng.EngagementNumber) AS TotalEngagements,
    COUNT(DISTINCT ms.StyleID) AS MusicalStylesBooked
FROM Customers AS cus
JOIN Engagements AS eng ON cus.CustomerID = eng.CustomerID
JOIN Entertainers AS ent ON eng.EntertainerID = ent.EntertainerID
JOIN Entertainer_Styles AS es ON ent.EntertainerID = es.EntertainerID
JOIN Musical_Styles AS ms ON es.StyleID = ms.StyleID
GROUP BY cus.CustomerID
HAVING COUNT(DISTINCT ms.StyleID) > 3
ORDER BY CustomerName;

---[4] Unbooked or Incomplete Profiles
--Q9. Identify entertainers who have missing or invalid phone numbers (e.g., NULL values or incorrectly formatted numbers). Include their stage name, phone number, and city, sorted alphabetically by stage name.
SELECT 
    ent.EntStageName AS StageName, 
    ent.EntPhoneNumber AS PhoneNumber, 
    ent.EntCity AS City
FROM Entertainers AS ent
WHERE 
    ent.EntPhoneNumber IS NULL
    OR NOT (ent.EntPhoneNumber ~ '^[0-9]{3}-[0-9]{3}-[0-9]{4}$')
ORDER BY ent.EntStageName;

--Q10. For each entertainer, include their stage name, city, missing/invalid fields (e.g., Email/Phone), and number of distinct musical styles they are associated with but have no engagements for. Sort the results alphabetically by stage name.
SELECT 
    ent.EntStageName AS StageName,
    ent.EntCity AS City,
    CASE 
        WHEN ent.EntEMailAddress IS NULL THEN 'Missing Email'
        WHEN ent.EntPhoneNumber IS NULL THEN 'Missing Phone'
        WHEN NOT (ent.EntPhoneNumber ~ '^[0-9]{3}-[0-9]{3}-[0-9]{4}$') THEN 'Invalid Phone Format'
        ELSE 'Valid Profile'
    END AS ProfileIssue,
    COUNT(DISTINCT es.StyleID) AS StylesWithoutEngagements
	
FROM Entertainers AS ent
LEFT JOIN Entertainer_Styles AS es ON ent.EntertainerID = es.EntertainerID
LEFT JOIN Engagements AS eng ON ent.EntertainerID = eng.EntertainerID
LEFT JOIN Musical_Styles AS ms ON es.StyleID = ms.StyleID

WHERE 
    -- Entertainers with no engagements
    NOT EXISTS (
        SELECT 1 
        FROM Engagements AS e 
        WHERE e.EntertainerID = ent.EntertainerID
    )
    OR 
    -- Missing or invalid profile information
    ent.EntEMailAddress IS NULL
    OR ent.EntPhoneNumber IS NULL
    OR NOT (ent.EntPhoneNumber ~ '^[0-9]{3}-[0-9]{3}-[0-9]{4}$')
    OR 
    -- Associated with styles but no engagements
    NOT EXISTS (
        SELECT 1
        FROM Engagements AS e
        JOIN Entertainer_Styles AS es_sub ON e.EntertainerID = es_sub.EntertainerID
        WHERE es_sub.StyleID = es.StyleID
    )
	
GROUP BY 
    ent.EntStageName, ent.EntCity, ent.EntEMailAddress, ent.EntPhoneNumber
	
ORDER BY StageName;