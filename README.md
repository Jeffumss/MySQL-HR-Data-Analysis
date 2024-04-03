# Analyzing HR Data Insights of Employee Demographics and Salary Trends (Using MySQL and Tableau)

## Introduction:
In a world driven by data, utilizing data analysis helps organizations discover valuable insights into various aspects of a company’s operations. One crucial area for every company is human resources (HR). Analyzing employee data can provide valuable information on a company’s workforce and help answer common business questions, which can lead to change and help cultivate a positive work culture. In this project, we will explore a comprehensive analysis of HR data, including a gender breakdown, age distribution, employment tenure, salary analysis across departments and job positions, employee count distribution between departments and job positions, turnover rate by department, and employment change over time. The focus of this analysis is to gain a better understanding of the factors that lead to employment termination and where improvements can be made to increase employee retention. The analysis is conducted using MySQL for all data cleaning and analysis, and Tableau Desktop for data visualization.

## Data Used:
The analysis is based on an HR database consisting of 6 different tables (employees, managers, departments, titles, salaries, and employeesdepartments junction table) containing over 300,000 employee rows and over 900,000 salary contract rows. The dataset encompasses hires from 1985 to 2000, terminations spanning 1985 to 2002, and ongoing employment up to 2024 when this analysis is being conducted. The dataset includes information such as an employee’s ID, an employee’s demographics (hire date, birth date, gender, and name), an employee’s department(s) worked in, an employee’s job title(s), and all of an employee’s salary contracts information.

The dataset used can be downloaded through the Dropbox link below:

https://www.dropbox.com/s/znmjrtlae6vt4zi/employees.sqle=1&dl=0&source=post_pageece01b8cb5eb

## Data Cleaning & Transformation:
Using MySQL Workbench, various data cleaning and transformation operations have been conducted on the “employees” table in the “employees” database. The provided code performs each of these steps.

1. Selecting the Database:
```sql
USE employees;
```
This code selects the “employees” database which has been created through the “employees.sql” file.

2. Viewing Table Structures:
```sql
DESCRIBE employees;
DESCRIBE dept_emp;
DESCRIBE departments;
DESCRIBE dept_manager;
DESCRIBE salaries;
DESCRIBE titles;
```
This code displays the structure of each one of the six tables in the
database. Here column names, data types, primary keys, and null
constraints are shown.

3. Adding the Age Column:
```sql
ALTER TABLE employees
ADD COLUMN age INT;

UPDATE employees
SET age = FLOOR((DATEDIFF(CURRENT_DATE(), birth_date) / 365));
```
This code adds a new integer column to the “employees” table, “age”, which
is calculated using the difference in days of the current date of the project
with an employee’s birth date column and then dividing by 365 days to
obtain the difference in years. Using the FLOOR function rounds down to
set an employee's age to the largest whole number.

4. Adding the Termination Date Column:
```sql
ALTER TABLE employees
ADD COLUMN termination_date DATE;

UPDATE employees e
  SET termination_date = (
  CASE WHEN
    (SELECT MAX(to_date)
    FROM dept_emp de
    WHERE de.emp_no = e.emp_no
    GROUP BY emp_no)
      <= CURRENT_DATE()
  THEN
    (SELECT MAX(to_date)
    FROM dept_emp de
    WHERE de.emp_no = e.emp_no
    GROUP BY emp_no)
  ELSE NULL END);
```
This code adds a new date column to the “employees” table,
“termination_date”, for employees who no longer work for the company. It
uses an employee’s maximum “to_date” of working for a department from
the “dept_emp” table to determine if that date is less than or equal to the
current date when executing. If true, it sets the “termination_date” to that
max “to_date” otherwise, the column will be NULL for all currently working
employees.

5. Adding the Years Worked Column:
```sql
ALTER TABLE employees
ADD COLUMN years_worked FLOAT;

UPDATE employees
  SET years_worked = (
  CASE
    WHEN termination_date IS NOT NULL
    THEN ROUND(DATEDIFF(termination_date, hire_date) / 365, 2)
    ELSE ROUND(DATEDIFF(CURRENT_DATE, hire_date) / 365, 2)
  END);
```
This code adds a new column of float type, “years_worked”, to the
“employees” table. Using a CASE statement, it determines whether to use an
employee’s “termination_date” or the “current_date” to calculate the
difference in years from their “hire_date” to find each employee’s tenure
with the company.

## Business Questions:
The company has an assortment of questions regarding the employee data
to help impact management decision-making. Below are the questions
followed by the MySQL code for obtaining the results needed.

1. How many employees are currently working in the company, have been
terminated, and the total number of employees in the database?
2. What is the gender breakdown for all employees, working employees,
and terminated employees for the company?
3. What is the gender breakdown of current employees between
departments?
4. What is the gender breakdown of current employees between job titles?
5. What is the gender breakdown for each job title in each department?
6. Which employees are current managers? Which department pays their
manager the highest salary? Which manager has been a manager for the
longest time?
7. What is the average age, youngest age, and oldest age of all employees in
the database?
8. What is the current average age of each department and each job title?
9. Which age group of employees has the highest turnover rate?
10. Which department has the greatest turnover rate?
11. How has the company’s employee count changed over time based on
hires and terminations dates?
12. What is the average tenure with the company for current employees,
terminated employees, and all employees?
13. Which terminated employees have worked the greatest number of
years?
14. Which departments have the greatest difference in tenure from
terminated employees compared to current employees?
15. How many employees have worked 10 or more years with the company?
What percentage of employees are tenured?
16. What is the distribution of terminated employees across departments?
17. What is the distribution and average salary of employees across job
titles?
18. What is the average salary per department for current employees?
19. How does the average salary of each department compare to the overall
average salary and how does each gender’s average salary compare to
the department's average salary of current employees?
20. How do the average salaries of all employees, current employees, and
terminated employees compare?
21. How many current employees per department are paid under the
department’s average salary?
22. How many employees per gender are below their department’s average
salary?
23. How does changing departments impact an employee’s salary? Which employees have the greatest compensation increases?
24. Which department has the greatest average salary increase when
transferring into the department?
25. How has employees’ salary changed over time from being hired to their
latest salary contract? Which employees have the greatest yearly salary
increase?
26. How do employees’ salaries fluctuate between contracts over time?

## MySQL Queries:
The provided MySQL code answers the various questions about the
employees in the HR analysis. All code assumes the existence of the
“employees” database and its tables provided from the employees.sql file.

1. Employee Breakdown:
```sql
SELECT
  *,
  (total_num_of_employees - working_num_of_employees) AS terminated_num_of_employees
FROM
  (SELECT
    COUNT(emp_no) AS total_num_of_employees
  FROM employees) sq1
    JOIN
      (SELECT
        COUNT(emp_no) AS working_num_of_employees
      FROM employees
      WHERE termination_date IS NULL) sq2;
```
This query calculates the count of employees in the “employees” table for
all employees, current employees, and terminated employees using
subqueries and joins them together.

2. Employee Gender Breakdown:
```sql
SELECT
  sq1.gender,
  total_num_of_employees,
  working_num_of_employees,
  terminated_num_of_employees
FROM
  -- total employees
  (SELECT
    gender,
    COUNT(emp_no) AS total_num_of_employees
  FROM employees
  GROUP BY gender) sq1
JOIN
  -- working employees
  (SELECT
    gender,
    COUNT(emp_no) AS working_num_of_employees
  FROM employees
  WHERE termination_date IS NULL
  GROUP BY gender) sq2
    ON sq1.gender = sq2.gender
JOIN
  -- terminated employees
  (SELECT
    gender,
    COUNT(emp_no) AS terminated_num_of_employees
  FROM employees
  WHERE termination_date IS NOT NULL
  GROUP BY gender) sq3
    ON sq1.gender = sq3.gender;
```
This query calculates the count of employees in the “employees” table for
all employees, current employees, and terminated employees based on
their gender, using subqueries with joins on the gender column.

3. Current Department Gender Breakdown:
```sql
SELECT
  d.dept_name, de.dept_no,
  e.gender,
  COUNT(e.emp_no) AS num_of_employees
FROM employees e
  JOIN dept_emp de
    ON e.emp_no = de.emp_no
    AND de.to_date >= CURRENT_DATE()
  JOIN departments d
    ON de.dept_no = d.dept_no
GROUP BY de.dept_no, e.gender
ORDER BY dept_no;
```
This query calculates the count of current employees per gender for each
department using the “employees” and the “dept_emp” table to get an
employee's current department they work in. It groups the number of
employees first by department number and then by gender.

4. Current Job Title Gender Breakdown:
```sql
SELECT
  t.title,
  e.gender,
  COUNT(e.emp_no) AS num_of_employees
FROM employees e
  JOIN titles t
    ON e.emp_no = t.emp_no
    AND t.to_date >= CURRENT_DATE()
GROUP BY t.title, e.gender
ORDER BY t.title;
```
This query calculates the count of current employees per gender for each
job title, using the “employees” table and the “titles” table with a group by
on an employee’s title and then gender.

5. Department Job Titles Gender Breakdown:
```sql
SELECT
  d.dept_name, d.dept_no,
  t.title,
  e.gender,
  COUNT(e.emp_no) AS num_of_employees
FROM employees e
  JOIN dept_emp de
    ON e.emp_no = de.emp_no
    AND de.to_date >= CURRENT_DATE()
  JOIN departments d
    ON de.dept_no = d.dept_no
  JOIN titles t
    ON e.emp_no = t.emp_no
    AND t.to_date = de.to_date
GROUP BY de.dept_no, t.title, e.gender
ORDER BY de.dept_no, t.title, num_of_employees;
```
This query calculates the number of current employees per gender for each
job title in each department. Joining the four tables used on employee ID
and department number and grouping by department number, then job
title, and lastly gender.

6. Current Managers Breakdown:
```sql
-- creating a view of the current managers' information
DROP VIEW IF EXISTS manager_info;
CREATE VIEW manager_info AS
  SELECT
    d.dept_name, d.dept_no,
    e.emp_no,
    CONCAT(e.first_name, ' ', e.last_name) AS full_name,
    t.title,
    e.age, e.gender, e.hire_date,
    dm.from_date, s.salary,
    ROUND(DATEDIFF(CURRENT_DATE, dm.from_date) / 365, 1) AS years_as_manager,
    ROUND(DATEDIFF(CURRENT_DATE, e.hire_date) / 365, 1) AS years_worked,
    ROUND(DATEDIFF(dm.from_date, e.hire_date) / 365, 1) AS years_before_management
  FROM dept_manager dm
    JOIN employees e ON dm.emp_no = e.emp_no
    JOIN departments d ON dm.dept_no = d.dept_no
    JOIN salaries s ON dm.emp_no = s.emp_no AND dm.to_date = s.to_date
    JOIN titles t ON dm.emp_no = t.emp_no AND dm.to_date = t.to_date
WHERE dm.to_date >= CURRENT_DATE;
```
```sql
SELECT *
FROM manager_info
ORDER BY salary DESC;
```
```sql
SELECT *
FROM manager_info
ORDER BY years_as_manager DESC;
```
The first query creates a view containing information on the current
department managers including employee demographics, current salary,
years working as a manager, years before becoming a manager, and total
years worked. The second query orders the department managers by their
salary descending to see the top-paying departments. The third query
orders the managers by their years serving as managers descending. Note:
The highest-paid managers are also some of the longest-working managers.

7. Employees Ages:
```sql
SELECT
  ROUND(AVG(age), 2) AS average_age,
  MIN(age) AS youngest_age,
  MAX(age) AS oldest_age,
  COUNT(*) AS num_of_employees
FROM employees;
```
This query calculates the average, minimum, and maximum age of all
employees in the “employees” table. Note: The average age of an employee
is 65 with a range from 59 to 72 years old.

8. Average Age of Departments and Job Titles:
```sql
SELECT
  de.dept_no,
  d.dept_name,
  ROUND(AVG(age), 2) AS average_age,
  COUNT(*) AS num_of_employees
FROM employees e
  JOIN dept_emp de
    ON e.emp_no = de.emp_no
    AND de.to_date = (SELECT MAX(to_date) FROM dept_emp WHERE emp_no = e.emp_no)
  JOIN departments d
    ON de.dept_no = d.dept_no
WHERE termination_date IS NULL
GROUP BY de.dept_no
ORDER BY average_age DESC, num_of_employees DESC;
```
```sql
SELECT
  t.title,
  ROUND(AVG(age), 2) AS average_age,
  COUNT(*) AS num_of_employees
FROM employees e
  JOIN titles t ON e.emp_no = t.emp_no
WHERE t.to_date >= CURRENT_DATE
GROUP BY t.title
ORDER BY average_age DESC;
```
The first query calculates the average age of current employees for each
department and orders the departments from oldest to youngest. The
second query calculates the average of current employees for each job title
from oldest to youngest. Note: The oldest department is Quality
Management and the oldest job position is Technique Leader.

9. Age Turnover Rank:
```sql
SELECT *,
  RANK() OVER(ORDER BY turnover_rate DESC) AS turnover_rank
FROM (
  SELECT
    sq1.age,
    sq1.total_employees,
    sq2.current_employees,
    (sq1.total_employees - sq2.current_employees) AS employees_terminated,
    CONCAT(ROUND((sq1.total_employees - sq2.current_employees) / total_employees
  FROM
    -- total employees
    (SELECT
      age,
      COUNT(*) AS total_employees
    FROM employees
    GROUP BY age
    ORDER BY age) sq1
JOIN
  -- only current employees
  (SELECT
    age,
    COUNT(*) AS current_employees
  FROM employees e
    JOIN dept_emp de ON e.emp_no = de.emp_no
  WHERE de.to_date >= CURRENT_DATE()
  GROUP BY age
  ORDER BY age) sq2
    ON sq1.age = sq2.age
  ) subquery
ORDER BY age;
```
This query calculates the count of all employees, current employees, and
terminated employees for each age. Using multiple subqueries of employee counts, it calculates the turnover rate grouping by age. Finally, it uses a
window function to rank each age by the turnover rate in descending order.
Note: The highest-ranked age with the highest turnover rate is 66, with 63
being the second highest, and 72 being the lowest.

10. Department Turnover Rate:
```sql
-- creating a view of the departments turnover info
DROP VIEW IF EXISTS department_turnover;
CREATE VIEW department_turnover AS
  SELECT *,
    CONCAT(ROUND(terminations/num_of_employees * 100, 2), '%') AS turnover_rate,
    (num_of_employees - terminations) AS current_working_employees
  FROM (
    SELECT
      d.dept_name,
      d.dept_no,
      COUNT(*) AS num_of_employees,
      SUM(CASE
        WHEN termination_date IS NOT NULL THEN 1 ELSE 0
      END) AS terminations
  FROM (
    -- subquery selecting each employees' latest dates of working
    (SELECT
      emp_no,
      MAX(from_date) AS max_from_date,
      MAX(to_date) AS max_to_date
    FROM dept_emp de
    GROUP BY emp_no) sq1
  -- joining the department an employee has worked in last
  JOIN dept_emp de
    ON de.emp_no = sq1.emp_no
    AND de.from_date = sq1.max_from_date
    AND de.to_date = sq1.max_to_date
  JOIN departments d ON de.dept_no = d.dept_no
  JOIN employees e ON de.emp_no = e.emp_no)
  GROUP BY dept_name) sq2
  ORDER BY turnover_rate DESC;
```
```sql
SELECT *
FROM department_turnover
ORDER BY turnover_rate DESC;
```
The first query creates a view to store each department’s number of
employees, terminations, and turnover rate. Using a subquery to select an
employee’s latest dates of working from the “dept_emp” table, joining it
back with the “dept_emp” table to obtain only their current department
working in, and then calculating the count of employees per each
department total. A CASE statement in another subquery is used to count
only the terminated employees for each department which is then used to
calculate the turnover rate for each department. The second query orders
the departments in the “department_turnover” view by turnover rate
descending to display the departments with the highest turnover
percentages.

11. Employee Count Change Over Time (Based on Hired and Termination Dates):
```sql
DROP VIEW IF EXISTS employee_change;
CREATE VIEW employee_change AS
  SELECT
    term_year AS year,
    (CASE WHEN hire_year IS NULL THEN 0 ELSE hires END) AS hires,
    terminations,
    ((CASE
      WHEN hire_year IS NULL THEN 0 ELSE hires END) - terminations)
    AS employee_net_change,
    ROUND(((hires - terminations) / hires) * 100, 2) AS net_change_percent,
    ROUND(hires / terminations, 2) AS net_hire_ratio,
    SUM(hires) OVER (ORDER BY term_year) AS rolling_hire_count,
    SUM(terminations) OVER (ORDER BY term_year) AS rolling_termination_count
  FROM (
    -- count of employees hired per year
    SELECT
      YEAR(hire_date) AS hire_year,
      COUNT(*) AS hires
    FROM employees
    GROUP BY hire_year
    ) sq1
  RIGHT JOIN (
  -- count of employees terminated per year
  SELECT
    YEAR(termination_date) AS term_year,
    COUNT(*) AS terminations
  FROM employees
  GROUP BY term_year
  HAVING term_year IS NOT NULL
  ) sq2
    ON sq1.hire_year = sq2.term_year
  ORDER BY year;
```
```sql
SELECT *
FROM employee_change
ORDER BY year;
```
The first query creates a view, “employee_change”, to store the number of
hires, terminations, employee count net change, and rolling totals from
each year of the company’s dataset range (1985–2002). Joining one subquery
of the count of hired employees each year with another subquery of the count of terminations for each year, on the years of each measure. A right
join was necessary due to the employees hired ending in 2000 and the
termination dates ending in 2002. In the outer query,
“employee_net_change” and rolling sums of hires and terminations are
calculated. In the second query, it selects the stored view and orders it by
years ascending from ’85 to ‘02.

12. Average Tenure of Employees:
```sql
SELECT *
FROM (
  -- average tenure of current employees
  SELECT
    ROUND(AVG(years_worked), 1) AS current_average_tenure
  FROM employees
  WHERE termination_date IS NULL) sq1
JOIN (
  -- average tenure of terminated employees
  SELECT
    ROUND(AVG(years_worked), 1) AS terminated_average_tenure
  FROM employees
  WHERE termination_date IS NOT NULL) sq2
  -- average tenure of all employees
JOIN (
  SELECT
  ROUND(AVG(years_worked), 1) AS overall_average_tenure
  FROM employees) sq3;
```
This query joins three subqueries together of average years worked from
the “employees” table for current employees, terminated employees, and all
employees.

13. Terminated Employees Tenure:
```sql
DROP VIEW IF EXISTS employees_terminated;
CREATE VIEW employees_terminated AS
  SELECT
    *,
    ROUND((years_worked - avg_terminated_tenure), 2) AS tenure_diff_from_avg
  FROM
    (SELECT
      e.emp_no,
      CONCAT(first_name, ' ', last_name) AS full_name,
      hire_date,
      termination_date,
      d.dept_name AS last_department,
      title AS last_position,
      salary AS last_salary,
      years_worked,
        (SELECT
          ROUND(AVG(years_worked), 1)
        FROM employees
        WHERE termination_date IS NOT NULL
        ) AS avg_terminated_tenure
  FROM employees e
    JOIN dept_emp de
      ON e.emp_no = de.emp_no
      AND e.termination_date = de.to_date
    JOIN departments d
      ON de.dept_no = d.dept_no
    LEFT JOIN salaries s
      ON e.emp_no = s.emp_no
      AND e.termination_date = s.to_date
      AND s.from_date = (SELECT MAX(from_date)
                        FROM salaries
                        WHERE emp_no = e.emp_no)
    LEFT JOIN titles t
      ON e.emp_no = t.emp_no
      AND de.to_date = t.to_date
      AND t.from_date = (SELECT MAX(from_date)
                        FROM titles
                        WHERE emp_no = e.emp_no)
  WHERE termination_date IS NOT NULL
  ORDER BY e.emp_no ) AS subquery;
```
```sql
SELECT *
FROM employees_terminated
ORDER BY years_worked DESC;
```
This query stores the records of terminated employees of the “employees”
database into a view consisting of data for each employee’s information,
“years_worked”, “last_salary”, “last_department”, and “last_position”
columns. Using a subquery in the SELECT statement, it calculates the
“avg_terminated_tenure” of the years worked for terminated employees. In
the outer query, the difference between the “avg_terminated_tenure”
column and an employee’s “years_worked” column is calculated as
“tenure_diff_from_avg”. Note: The greatest difference of years from the
average tenure of terminated employees, 7.4 years, is 10 more years worked.

14. Departments Average Tenure:
```sql
SELECT
  overall_tenure.dept_no,
  overall_tenure.dept_name,
  dept_avg_tenure,
  terminated_avg_tenure,
  ROUND((dept_avg_tenure - terminated_avg_tenure), 2) AS tenure_difference
FROM (
  -- average years worked per department of terminated employees
  SELECT
    d.dept_no,
    d.dept_name,
    ROUND(AVG(years_worked), 2) AS terminated_avg_tenure
  FROM employees e
    JOIN dept_emp de
      ON e.emp_no = de.emp_no
      AND de.to_date = e.termination_date
    JOIN departments d
      ON de.dept_no = d.dept_no
  GROUP BY dept_name
  ) AS terminated_tenure
JOIN (
  -- average years worked per department of current employees
  SELECT
    d.dept_no,
    d.dept_name,
    ROUND(AVG(years_worked), 2) AS dept_avg_tenure
  FROM employees e
    -- subquery to select employee's latest department dates
    JOIN (
      SELECT emp_no, MAX(from_date) AS max_from_date, MAX(to_date) AS max_to_date
      FROM dept_emp
      GROUP BY emp_no) de1
    ON e.emp_no = de1.emp_no
  JOIN dept_emp de
    ON de.emp_no = e.emp_no
    AND de.from_date = de1.max_from_date
    AND de.to_date = de1.max_to_date
  JOIN departments d
    ON de.dept_no = d.dept_no
WHERE e.termination_date IS NULL
GROUP BY dept_name
  ) AS overall_tenure
    ON terminated_tenure.dept_no = overall_tenure.dept_no
ORDER BY tenure_difference DESC;
```
This query returns the average tenure using the “years_worked” column for
each department in the “departments” table. It joins two subqueries
“terminated_tenure” and “overall_tenure” on the “department_no” column. In the outermost query, it calculates the difference between the two
department averages of “years_worked” for each of the employee group sets
(terminated and working). Ordering the results descending by the
“tenure_difference” column to view the departments with the greatest
difference in tenure averages between the groups of employees. Note: All
the departments had a relative average of 34 years of tenure for current
employees and 7.4 years of tenure for terminated employees.

15. Long-Tenured(10+ Years) Employees:
```sql
SELECT *,
  ROUND((tenured_employees / total_employees) * 100, 1) AS percent_of_total
FROM
  (
    SELECT
      COUNT(*) AS tenured_employees,
      (SELECT
        COUNT(*)
      FROM employees) AS total_employees
    FROM employees
    WHERE years_worked >= 10) subquery;
```
This query finds the number of employees who have long-term tenure
status for the company. In the outer query of the two employee counts, the
“percentage_of_total” column is calculated. Note: 86% of the total
employees, have worked 10 or more years.

16. Department Termination Distribution:
```sql
SELECT
  last_department,
  COUNT(emp_no) AS num_of_employees
FROM employees_terminated
GROUP BY last_department
ORDER BY num_of_employees DESC;
```
This query calculates the count of terminated employees of each
department in the “employees_terminated” view and is ordered by the
count from highest to lowest. Note: The Development (15,572) and
Production (13,371) departments have the most employees terminated.

17. Job Title Employee Distribution and Salary Average:
```sql
SELECT
  title,
  ROUND(AVG(salary), 2) AS avg_salary,
  COUNT(*) AS working_num_of_employees
FROM titles t
LEFT JOIN salaries s
  ON t.emp_no = s.emp_no
  AND t.to_date = s.to_date
WHERE t.to_date > CURRENT_DATE
GROUP BY title
ORDER BY avg_salary DESC;
```
This query calculated the number of employees currently working for each
job title in the company. It also calculates the employee’s average salary in each position, ordering the results in the highest average salary. Note:
Senior Staff has the greatest employee salary average with the second-most
largest amount of employees in the company.

18. Departments Average Salary:
```sql
SELECT
  d.dept_no,
  dept_name,
  ROUND(AVG(salary), 0) AS dept_avg_salary
FROM dept_emp de
LEFT JOIN salaries s
  ON de.emp_no = s.emp_no
  AND de.to_date = s.to_date
JOIN departments d
  ON de.dept_no = d.dept_no
WHERE de.to_date >= CURRENT_DATE()
GROUP BY dept_no
ORDER BY dept_avg_salary;
```
This query calculates the average salary of current employees grouped by
the department they work in. Using a left join with the “salaries” table joins
all 240,124 current employees from the “dept_emp” table and orders the
departments from lowest to highest average salaries. Note: The Human
Resources department is the lowest ($63,643) paying department and the
Sales department is the highest ($89,006).

19. Departments Average Salary with Gender Breakdown:
```sql
SELECT
  dept_no,
  dept_name,
  overall_avg_salary,
  dept_avg_salary,
  (dept_avg_salary - overall_avg_salary) AS dept_salary_difference,
  gender,
  dept_gender_avg_salary,
  (dept_gender_avg_salary - dept_avg_salary) AS gender_diff_from_dept_avg
FROM (
  SELECT
    de.dept_no,
    d.dept_name,
    dept_avg_salary,
    e.gender,
    ROUND(AVG(salary), 0) AS dept_gender_avg_salary,
      -- subquery for overall average salary of current employees
      (SELECT
        ROUND(AVG(salary), 0)
      FROM salaries
      WHERE to_date >= CURRENT_DATE()) AS overall_avg_salary
FROM dept_emp de
LEFT JOIN salaries s
  ON de.emp_no = s.emp_no
  AND de.to_date = s.to_date
JOIN
  -- subquery to find department average salary
  (SELECT
    dept_no,
    ROUND(AVG(salary), 0) AS dept_avg_salary
  FROM dept_emp de
    LEFT JOIN salaries s
      ON de.emp_no = s.emp_no
      AND de.to_date = s.to_date
  WHERE de.to_date >= CURRENT_DATE()
  GROUP BY dept_no) as subquery
    ON de.dept_no = subquery.dept_no
JOIN departments d ON de.dept_no = d.dept_no
JOIN employees e ON de.emp_no = e.emp_no
WHERE de.to_date >= CURRENT_DATE()
GROUP BY dept_name, e.gender
ORDER BY de.dept_no, e.gender) sq;
```
This query compares the averages of employees’ salaries of each gender to
each department’s average salary, as well as the overall average salary of all
the departments. The inner-most subquery, as “subquery”, calculates the
average of the “salary” column of working employees grouped by the
“dept_no” column and joined to the outer query obtaining the average
salary grouped by “dept_name” and “gender” columns. The subquery used
in the SELECT statement returns the “overall_avg_salary” column of all
current employees in any department. Calculated in the outer-most query,
is the difference between the “dept_avg_salary” column and the
“overall_avg_salary” column for each department as
“dept_salary_difference”. Then, the difference between each gender’s
average to the department’s average is calculated as
“gender_diff_from_dept_avg”. Note: Female employees in the Marketing
department have the greatest compensation gap,-$341, from the
department average, and females in Human Resources have a gap of $317
more than the department average.

20. Employee Salary Comparison:
```sql
WITH
all_emp_salary AS (
  SELECT
    ROUND(AVG(salary), 0) AS all_avg_salary
  FROM employees e
  JOIN salaries s
    ON e.emp_no = s.emp_no
  WHERE s.from_date = (SELECT MAX(from_date)
                      FROM salaries
                      WHERE emp_no = s.emp_no)
  ),
current_emp_salary AS (
  SELECT
    ROUND(AVG(salary), 0) AS current_avg_salary
  FROM employees e
  JOIN salaries s
    ON e.emp_no = s.emp_no
  WHERE s.to_date > CURRENT_DATE()
  ),
terminated_emp_salary AS (
  SELECT
    ROUND(AVG(salary), 0) AS terminated_avg_salary
  FROM employees e
  JOIN salaries s
    ON e.emp_no = s.emp_no
    AND s.from_date = (SELECT MAX(from_date)
                      FROM salaries
                      WHERE emp_no = s.emp_no)
  WHERE e.termination_date IS NOT NULL
  )

SELECT *
FROM all_emp_salary
JOIN current_emp_salary
JOIN terminated_emp_salary;
```
This query joins multiple CTEs together to calculate the average salary of
three different employment groups, currently working, terminated, and
total employees, and compares them alongside each other. Each of the CTEs
performs the aggregate function average on the “salaries” table specifically
for the subset group of employees. Joining each row together allows the
result to output the three average salaries side-by-side. Note: Terminated
employees averaged $8,300 less than the overall average ($69,915) while
current employees made $2,000 more than the average.

21. Employee Salary Gaps:
```sql
-- creating a view of current employee's salary comparison to department's average
DROP VIEW IF EXISTS emp_salary_comparison;
CREATE VIEW emp_salary_comparison AS
  SELECT
    e.emp_no,
    CONCAT(first_name, ' ', last_name) AS full_name,
    gender,
    age,
    years_worked,
    salary,
    d.dept_no,
    d.dept_name,
    dept_avg_salary,
    title,
    -- determines if employee's salary over/under department's average
    CASE
      WHEN salary > dept_avg_salary THEN 'above department average'
      WHEN salary IS NULL THEN 'no salary data'
      ELSE 'below department average'
    END AS current_salary_comparison,
    (salary - dept_avg_salary) AS salary_difference
  FROM dept_emp de
  JOIN
    -- subquery to get departments' average salary
    (SELECT
      dept_no,
      ROUND(AVG(salary), 0) AS dept_avg_salary
    FROM dept_emp de
    LEFT JOIN salaries s
      ON de.emp_no = s.emp_no
      AND de.to_date = s.to_date
    WHERE de.to_date >= CURRENT_DATE()
    GROUP BY de.dept_no) sq1
    ON de.dept_no = sq1.dept_no
  JOIN departments d
    ON de.dept_no = d.dept_no
  LEFT JOIN salaries s
    ON de.emp_no = s.emp_no
    AND de.to_date = s.to_date
  JOIN employees e
    ON de.emp_no = e.emp_no
  JOIN titles t
    ON de.emp_no = t.emp_no
    AND de.to_date = t.to_date
  WHERE de.to_date >= CURRENT_DATE();
```
```sql
SELECT
dept_name,
dept_avg_salary,
count(emp_no) AS emp_count
FROM emp_salary_comparison
WHERE current_salary_comparison LIKE 'below%'
AND salary_difference < 0
GROUP BY dept_name
ORDER BY emp_count DESC;
```
The first query creates a view of current employees’ info from each table
and compares the salary of the employee to their current department’s
average salary. Using a subquery to calculate each department’s average
salary, it’s then referenced in the outer query to compare the difference of
each employee’s individual salary. In the “current_salary_comparison”
column, a string result is given for whether an employee is above or below
their department average. The “salary_difference” column calculates the
difference as a decimal value of the two salary amounts. The second query
groups the employees whose salary is below their department’s average
salary per department. It obtains the department’s name and average salary
along with the count of employees below the average salary for each
department. Note: There are a total of 43,175 employees below their department’s average salary, with Development (11,129) and Production
(9,693) having the most underpaid employees.

22. Employee Pay Gap Gender Breakdown:
```sql
SELECT
  emp_sal.gender,
  COUNT(*) AS num_of_under_avg_employees,
  total_working_employees,
  CONCAT(ROUND((COUNT(*) / total_working_employees) * 100, 2), '%')
    AS percent_emp_under_avg
FROM
  emp_salary_comparison AS emp_sal
JOIN
  -- subquery for total count of current workers
  (SELECT
    gender,
    COUNT(*) AS total_working_employees
  FROM emp_salary_comparison
  GROUP BY gender) AS subquery
    ON subquery.gender = emp_sal.gender
WHERE current_salary_comparison LIKE 'below%'
AND salary_difference < 0
GROUP BY emp_sal.gender;
```
This query calculates the percent of employees who are below their
department’s average from the “emp_salary_comparison” stored view
broken down by gender. Using the count of underpaid employees divided
by the total count of all current workers, the “percent_emp_under_avg”
column is calculated for each gender. Note: Females, 18.1%, are slightly
more underpaid than males out of their total employees.

23. Employee Salary Difference Between Department Transfers:
```sql
-- creating a view of employees who changed departments salary info
DROP VIEW IF EXISTS emp_dept_salary_change;
CREATE VIEW emp_dept_salary_change AS
  SELECT
    dept1.emp_no,
    dept1.dept_no AS first_dept_no,
    dept1.dept_name AS first_dept_name,
    dept1.from_date AS first_dept_start_date,
    dept1.salary AS first_dept_salary,
    dept2.dept_no AS second_dept_no,
    dept2.dept_name AS second_dept_name,
    dept2.from_date AS second_dept_start_date,
    dept2.salary AS second_dept_salary,
    (dept2.salary - dept1.salary) AS salary_difference
  FROM
  -- subquery returns an employee's salary and start date for the first department
    (SELECT s.emp_no, s.salary, de.from_date, de.dept_no, d.dept_name
    FROM salaries s
      JOIN dept_emp de ON s.emp_no = de.emp_no
      JOIN departments d ON de.dept_no = d.dept_no
    -- where the salary start date is the max date that is less than or equal to the end date of working in the first dept
    WHERE s.from_date = (SELECT MAX(from_date)
    FROM salaries
    WHERE emp_no = s.emp_no
    AND from_date <= de.to_date)
    ) AS dept1
  JOIN
    -- subquery returns an employee's salary and start date for the second department
    (SELECT s.emp_no, s.salary, de.from_date, de.dept_no, d.dept_name
    FROM salaries s
      JOIN dept_emp de ON s.emp_no = de.emp_no
      JOIN departments d ON de.dept_no = d.dept_no
    -- where the salary start date is the min date is greater than to the start date
    WHERE s.from_date = (SELECT MIN(from_date)
    FROM salaries
    WHERE emp_no = s.emp_no
    AND from_date >= de.from_date)
    ) AS dept2
  ON dept1.emp_no = dept2.emp_no
  AND dept1.from_date < dept2.from_date;
```
```sql
SELECT *
FROM emp_dept_salary_change
ORDER BY salary_difference DESC;
```
The first query creates a stored view of employees who have worked in
multiple departments and computes the difference in salary from leaving
the first department and transferring to the new department. The query
joins two subqueries, one subquery that returns an employee’s last salary
while working in their first department, and another subquery that returns
the first salary of working with the new department. Each subquery returns
the start dates of the salary contracts and each department the employee
worked in. In the outer query, the “salary_difference” column is calculated
for the new and old salaries after transferring departments. The second
query selects the rows of the “emp-dept_salary_change” view, ordering
employees with the greatest increase in salary between switching
departments. Note: 9,590 employees have worked in multiple departments.

24. Department Employment Transfers:
```sql
SELECT
  second_dept_name AS dept_transferred_in,
  ROUND(AVG(salary_difference), 2) AS avg_dept_salary_difference,
  COUNT(*) AS num_of_employees_transferred_in
FROM emp_dept_salary_change
GROUP BY second_dept_name
ORDER BY avg_dept_salary_difference DESC;
```
This query calculates the average salary difference of employees who
transferred departments grouped by the employees’ department they
transferred into. Ordering the departments by the
“avg_dept_salary_difference” column in descending order shows which
departments have the greatest pay increases for employees who’ve
transferred in. Note: The Sales department has the greatest average salary
increase with the third-lowest count of employees who’ve transferred in.

25. Employee All-time Salary Change:
```sql
-- creating a view of an employee's starting salary to end salary difference
DROP VIEW IF EXISTS emp_salary_years_worked;
CREATE VIEW emp_salary_years_worked AS
  SELECT
    e.emp_no,
    CONCAT(first_name, ' ', last_name) AS full_name,
    gender,
    hire_date,
    termination_date,
    years_worked,
    s1.start_salary,
    s2.end_salary,
    (s2.end_salary - s1.start_salary) AS alltime_salary_difference,
    ROUND((s2.end_salary - s1.start_salary) / years_worked, 0) AS salary_flux_per_years_worked
  FROM (
    -- subquery for first salary
    SELECT
    emp_no,
    salary AS start_salary,
    from_date AS start_date,
    to_date AS end_date
    FROM salaries s
    WHERE from_date = (SELECT MIN(from_date) FROM salaries WHERE emp_no = s.emp_no)
    ) AS s1
  JOIN (
    -- subquery for last salary
    SELECT
    emp_no,
    salary AS end_salary,
    from_date AS start_date,
    to_date AS end_date
    FROM salaries s
    WHERE from_date = (SELECT MAX(from_date) FROM salaries WHERE emp_no = s.emp_no)
    ) AS s2
      ON s1.emp_no = s2.emp_no
  JOIN employees e
      ON s1.emp_no = e.emp_no;
```
```sql
SELECT *
FROM emp_salary_years_worked
ORDER BY salary_flux_per_years_worked DESC;
```
The first query creates a view to store employees’ salary data of each
employee’s starting salary, “start_salary” when hired, and ending salary or
latest salary, “end_salary”. It calculates the difference between the two
salaries while also factoring an employee’s years worked. Dividing the
difference between the first and last salaries by the number of years worked
finds each employee’s “salary_flux_per_years_worked”. The second query
orders the 101,796 employees' IDs in the “salaries” table, highest to lowest on their salary fluctuation per their years worked. Note: The greatest alltime
salary increase was $53,875 and the greatest salary decrease of -$988.

26. Employee Salary Contract Fluctuation:
```sql
SELECT
  emp_no,
  from_date,
  to_date,
  -- calculating each salary contract's duration in years
  ROUND((CASE
    WHEN to_date != '9999-01-01' THEN DATEDIFF(to_date, from_date) / 365
    ELSE DATEDIFF(CURRENT_DATE, from_date) / 365
  END), 1) AS contract_duration,
  salary AS current_pay,
  LAG(salary) OVER w AS previous_pay,
  (salary - LAG(salary) OVER w) AS pay_fluctuation,
  LEAD(salary) OVER w AS next_pay
FROM salaries
WINDOW w AS (PARTITION BY emp_no ORDER BY from_date)
ORDER BY emp_no, from_date;
```
This query shows each employee’s salary fluctuation while working in the
company for each contract. Using window functions, the results compare
an employee’s salary with their previous salary and future salary.
Partitioning by the “emp_no” column ordered from earliest to latest
“from_date”, calculates the salary difference of the current salary from their
previous salary as “pay_fluctuation”. Also, with the CASE statement, an
employee’s contract duration is calculated from the current day. Note:
There are 967,330 salary contracts for the 101,796 employees in the salaries table.

## Business Operations Stored Procedures:
The company’s Human Resources department has daily operations that are
conducted multiple times throughout the day. The company has requested
some different stored procedures that would make executing these
operational tasks more efficient for their employees.

**Employee Salary Function**

HR wants to be able to quickly query an employee’s least or greatest salary
and the difference between them. Create a function that can obtain an
employee’s minimum salary, maximum salary, or salary difference between
the two extreme values. The user will enter an employee’s ID number along
with whether they want to find the min, max, or difference as the
parameters.
```sql
DROP FUNCTION IF EXISTS emp_salary;
DELIMITER $$
CREATE FUNCTION emp_salary (p_emp_no INT, p_string VARCHAR(255))
  RETURNS VARCHAR(255)
  DETERMINISTIC
  BEGIN
    DECLARE p_emp_salary VARCHAR(255);

    IF p_string LIKE '%max%'
      THEN
      SET p_string = 'highest';
      SELECT MAX(salary)
      INTO p_emp_salary
      FROM salaries
      WHERE emp_no = p_emp_no;
    ELSEIF p_string LIKE '%min%'
      THEN
      SET p_string = 'lowest';
      SELECT MIN(salary)
      INTO p_emp_salary
      FROM salaries
      WHERE emp_no = p_emp_no;
    ELSE
      SET p_string = 'salary difference';
      SELECT (MAX(salary)) - (MIN(salary))
      INTO p_emp_salary
      FROM salaries
      WHERE emp_no = p_emp_no;
      END IF;
    SET p_emp_salary = CONCAT('Employee ', p_emp_no, '''s ', p_string, ' salary is $', p_emp_salary, '.');
    RETURN p_emp_salary;
  END $$
DELIMITER ;
```
```sql
SELECT
  emp_salary(11356, 'min'),
  emp_salary(11356, 'max'),
  emp_salary(11356, 'diff');
```
The first query creates a stored function, “emp_salary”, that takes two
parameters “p_emp_no” and “p_string” and returns the variable
“p_emp_salary”. The function contains an IF statement that determines
whether “p_string” is calling for the minimum, maximum, or difference of
salaries. Finally, it sets and returns “p_emp_salary” for the employee’s ID,
“p_emp_no”, and the salary value in the form of a sentence. The second
query calls the stored function inside of the SELECT statement with employee number 11356, for each of the three options of the function. Note:
Any string input that does not contain ‘min’ or ‘max’ will return the
difference.

**Employee Current Department Procedure**

HR would like to be able to immediately know an employee’s department
they are working in. Create a stored procedure that takes in any employee’s
ID number and returns the department name and number that they are
currently working in.
```sql
DROP PROCEDURE IF EXISTS employee_department;
DELIMITER $$
CREATE PROCEDURE employee_department(IN p_emp_no INT)
  BEGIN
    SELECT
      de.emp_no,
      de.dept_no,
      d.dept_name
    FROM
      (SELECT emp_no, MAX(from_date) AS from_date_max
      FROM dept_emp
      GROUP BY emp_no) sq1
    JOIN dept_emp de
      ON sq1.emp_no = de.emp_no
      AND sq1.from_date_max = de.from_date
    JOIN departments d
      ON de.dept_no = d.dept_no
    WHERE de.emp_no = p_emp_no;
  END $$
DELIMITER ;
```
```sql
CALL employee_department(400000);
```
The first query creates the procedure “employee_department” which takes
in one integer parameter, “p_emp_no”, an employee’s ID number and
returns the employee’s ID with the most current department name and
number. In the subquery, employees’ max “from_date” from the
“dept_emp” table is obtained and joined back with the same table to return
only the employee’s most current “dept_no”. The second query calls the
stored procedure for employee number 400000 and returns the most recent
department worked in.

## Employee Information Stored Views:
The company would like to create some stored views that aggregate the
most current data of each employee in the database from all of the tables in
the “employees” database. Below are the queries for creating views to store
the data that can be used for visualizations.

**All Employees Info**
```sql
DROP VIEW IF EXISTS employee_info;
CREATE VIEW employee_info AS
  SELECT
    e.*,
    de.dept_no,
    d.dept_name,
    de.from_date AS deparment_start,de.to_date AS department_end,
    t.title AS job_position,
    t.from_date AS job_start,
    t.to_date AS job_end,
    s.salary,
    s.from_date AS salary_start,
    s.to_date AS salary_end
  FROM (
    (SELECT
    emp_no,
    MAX(from_date) AS max_from_date,
    MAX(to_date) AS max_to_date
    FROM dept_emp de
    GROUP BY emp_no) sq1
  JOIN dept_emp de
    ON de.emp_no = sq1.emp_no
    AND de.from_date = sq1.max_from_date
    AND de.to_date = sq1.max_to_date
  JOIN departments d
    ON de.dept_no = d.dept_no
  JOIN employees e
    ON de.emp_no = e.emp_no
  LEFT JOIN salaries s
    ON sq1.emp_no = s.emp_no
    AND sq1.max_to_date = s.to_date
    AND s.from_date = (SELECT MAX(from_date) FROM salaries WHERE emp_no = s.emp_no)
  LEFT JOIN titles t
    ON de.emp_no = t.emp_no
    AND sq1.max_to_date = t.to_date
    AND t.from_date = (SELECT MAX(from_date) FROM titles WHERE emp_no = t.emp_no));
```
This query creates a stored view consisting of all 300,024 total employees in
the “employees” database. It joins each employee’s data from each table on
the “emp_no” column as well as the maximum “from_date” and “to_date”
columns for each of the tables. The dates from each table differ, therefore,
using a subquery in the joins on the “from_date” column retrieves the latest
row for each employee for each of the tables. A left join with the salaries tables is used because that table only includes data for 101,796 employees.
The view is stored in the “employees” database and will be used for future
visualizations.

**Current Employees Info**
```sql
DROP VIEW IF EXISTS current_employees;
CREATE VIEW current_employees AS
  SELECT *
  FROM employee_info
  WHERE termination_date IS NULL;
```
This query creates a new view using the previously created “employee_info”
view where the “termination_date” is null. This stores the 240,124 current
employees in its own view.

**Terminated Employees Info**
```sql
DROP VIEW IF EXISTS terminated_employees;
CREATE VIEW terminated_employees AS
  SELECT *
  FROM employee_info
  WHERE termination_date IS NOT NULL;
```
This query creates a new view using the previously created “employee_info”
view where the “termination_date” is not null. The 59,900 terminated
employees’ data is stored in its own view.

## Data Visualization - Tableau:
![Gender Dashboard](https://github.com/Jeffumss/MySQL-HR-Data-Analysis/assets/87340276/6e5eb58f-5913-43aa-a6bf-c3586f5b0f7b)
![Departments Dashboard](https://github.com/Jeffumss/MySQL-HR-Data-Analysis/assets/87340276/cafa5756-fb84-455d-be0f-37aa7d3fab0c)
![Managers Dashboard](https://github.com/Jeffumss/MySQL-HR-Data-Analysis/assets/87340276/e8496ced-234d-4aa2-beab-1a434767cbb9)
![Terminated Employees Dashboard](https://github.com/Jeffumss/MySQL-HR-Data-Analysis/assets/87340276/4e1d0ea1-4972-4002-a96a-7bdbc159c31b)

## Summary of Findings:
- The company’s employees database consists of 300,024 total employees,
240,124 currently working employees, and 59,900 terminated employees.
- There are more male employees than female employees in all departments and job positions, as well as males, have higher salaries than females on average.
- About 86% of employees (257,430) have worked 10 or more years.
- Terminated employees worked for an average of 7 years with an average
salary of $62,000, approximately $10,000 less than current employees.
- The average turnover rate for all departments is 20%, with Quality
Management having the greatest turnover rate, while Development
(15,572) and Production (13,371) experienced the highest number of
employees terminated.
- Midway through the year 1997 to 1998, the company’s hires-toterminations
ratio broke even, and starting in 1998 to 2002, the company
terminated more employees than it hired.
- The Sales department has the highest average salary ($89,000), about
$17,000 more than the average for all departments ($72,000).
- Senior Staff have the highest average salary ($80,500) of all job
positions with Managers ($78,000) and Senior Engineers ($71,000)
following.
- Senior Engineers make up the greatest portion of current employees,
86,000 employees (35.8%), with Senior Staff, 82,000 employees
(34.2%), following second.
- Marketing, Sales, and Finance departments have the highest-paying job
titles, with some staff employees being paid more than other
departments’ managers.
- Development (61,386), Production (53,304), and Sales (37,701)
departments have the greatest number of employees working.
- Male managers make almost $4,000 more than female managers.
- The average age of all managers is 64 years old, with the oldest being 71 and the youngest being 59.
- The highest-paid department manager, Marketing ($106,000), makes
approximately $50,000 more than the lowest-paid manager, Production ($57,000).
- The Customer Service and Production managers have the least years
worked as a manager (28 years), as well as the least salaries.

## Limitations:
_Some employees (198,228, 66%) had no salary data in the salaries table._

_Hire dates end in 2000 and terminations dates end in 2002 while the current
working employees go on through 2024._

_Some employees’ from-dates and to-dates in tables are the same dates._

_Data on an employee’s race and ethnicity was not collected._
