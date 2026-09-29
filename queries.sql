-- 1. Доля решенных в SLA(общая)
SELECT On_time, ROUND((1.0 * COUNT(*) / (SELECT COUNT(*) FROM incidents WHERE status = 'resolved')) * 100, 2) AS SLA
FROM (
    SELECT i.incident_id, i.team_id, i.priority_id, i.status, i.resolved_at, i.created_at, p.priority_name, p.sla_hours,
        CASE WHEN (julianday(i.resolved_at) - julianday(i.created_at)) * 24 < p.sla_hours THEN 'Yes' ELSE 'No' END AS On_time
    FROM incidents AS i
    JOIN priorities AS p ON i.priority_id = p.priority_id
    WHERE status = 'resolved')
GROUP BY On_time;


-- 2. SLA по командам
SELECT team_name,
    COUNT(*) AS total,
    SUM(CASE WHEN diff = 1 THEN 1 ELSE 0 END) AS in_sla,
    ROUND(100.0 * SUM(CASE WHEN diff = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS sla_percent
FROM(
    SELECT i.incident_id, t.team_name,
        (julianday(i.resolved_at) - julianday(i.created_at)) * 24 < p.sla_hours AS diff
    FROM incidents AS i
    JOIN teams AS t ON i.team_id = t.team_id
    JOIN priorities AS p ON i.priority_id = p.priority_id
    WHERE i.status = 'resolved') AS sub
GROUP BY team_name;

-- 3. SLA по приоритетам
SELECT p.priority_name,
    ROUND(100.0 * SUM(CASE WHEN ((julianday(resolved_at) - julianday(created_at)) * 24) < p.sla_hours THEN 1 ELSE 0 END)/ COUNT(*), 2) AS in_SLA
FROM incidents AS i
JOIN priorities AS p ON i.priority_id = p.priority_id
WHERE i.status = 'resolved'
GROUP BY p.priority_name;

--4. Среднее время решения по командам
SELECT t.team_name, ROUND(AVG((julianday(resolved_at) - julianday(created_at)) * 24), 2) AS avg_complete
FROM incidents AS i
JOIN teams AS t ON t.team_id = i.team_id
WHERE i.status = 'resolved'
GROUP BY i.team_id, t.team_name;

--5. Динамика инцидентов по дням
SELECT strftime('%Y-%m-%d', created_at) AS inc_date, COUNT(*) AS cnt
FROM incidents
GROUP BY inc_date
ORDER BY cnt ASC;

--6.Топ категорий по просроченным инцидентам
SELECT c.category_name, SUM(CASE WHEN (julianday(resolved_at) - julianday(created_at)) * 24 > p.sla_hours THEN 1 ELSE 0 END) AS not_in_SLA
FROM incidents AS i
JOIN categories AS c ON i.category_id = c.category_id
JOIN priorities AS p ON i.priority_id = p.priority_id
WHERE i.status = 'resolved'
GROUP BY c.category_name
ORDER BY not_in_SLA DESC;
