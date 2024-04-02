-- NEW PROJECT --

-- selecting my database
	USE employees;


-- understanding the structure of each table in the database
	DESCRIBE employees;
    DESCRIBE dept_emp;
    DESCRIBE departments;
    DESCRIBE dept_manager;
    DESCRIBE salaries;
    DESCRIBE titles;

-- DATA CLEANING/TRANSFORMATION -- 
-- adding the Age column to the employees table
	ALTER TABLE employees
	ADD COLUMN age INT;
   
	UPDATE employees
	SET age = FLOOR((DATEDIFF(CURRENT_DATE(), birth_date) / 365));


-- adding the Termination Date column to the employees table
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
	
	
	SELECT *
	FROM employees e
	WHERE termination_date IS NOT NULL;


-- adding the Years Worked column
	-- if terminated (termed date - hire date)
	-- if still working (current date - hire date)
	ALTER TABLE employees
    ADD COLUMN years_worked FLOAT;
    
    UPDATE employees
    SET years_worked = (
		CASE
			WHEN termination_date IS NOT NULL THEN ROUND(DATEDIFF(termination_date, hire_date) / 365, 2)
            ELSE ROUND(DATEDIFF(CURRENT_DATE, hire_date) / 365, 2)
		END);
    
    SELECT *
    FROM employees e
    ORDER BY years_worked DESC;

-- BUSINESS QUESTIONS -- 

-- 1. How many employees are currently working in the company, have been terminated, and total number of employees in the database?
	-- counting the number of total employees, current employees, and terminated
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
    
----------------------

-- 2. What is the gender breakdown for all employees, working employees, and terminated employees for the company?
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
			
----------------------

-- 3. What is the gender breakdown of current employees between departments?
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

----------------------

-- 4. What is the gender breakdown of current employees between job titles?
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

----------------------

-- 5. What is the gender breakdown for each job title in each department?
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

---------------------- 

-- 6. Which employees are current managers?
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

-- Which department pays their manager the highest salary?
    SELECT *
    FROM manager_info
    ORDER BY salary DESC;

-- Which manager has been a manager for the longest time?
    SELECT *
    FROM manager_info 
    ORDER BY years_as_manager DESC;

---------------------- 

-- 7. What is the average age, youngest age, and oldest age of all employees in the database?
    SELECT
		ROUND(AVG(age), 2) AS average_age,
		MIN(age) AS youngest_age, 
        MAX(age) AS oldest_age,
        COUNT(*) AS num_of_employees
	FROM employees;

----------------------

-- 8. What is the average age of each department and each job title?
	-- finding the average age of each department's current employees
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
    
	-- finding the average age of each job position for current employees
	SELECT 
		t.title,
        ROUND(AVG(age), 2) AS average_age,
        COUNT(*) AS num_of_employees
    FROM employees e
		JOIN titles t ON e.emp_no = t.emp_no
	WHERE t.to_date >= CURRENT_DATE
    GROUP BY t.title
    ORDER BY average_age DESC;

----------------------    
 
-- 9. Which age group of employees has the highest turnover rate?
	SELECT *,
		RANK() OVER(ORDER BY turnover_rate DESC) AS turnover_rank
    FROM (
		SELECT
			sq1.age,
			sq1.total_employees,
			sq2.current_employees,
			(sq1.total_employees - sq2.current_employees) AS employees_terminated,
            CONCAT(ROUND((sq1.total_employees - sq2.current_employees) / total_employees * 100, 2), '%') AS turnover_rate
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

---------------------- 

-- 10. Which department has the greatest turnover rate?
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

	SELECT *
    FROM department_turnover
    ORDER BY turnover_rate DESC;
    
----------------------

-- 11. How has the company's employee count changed over time based on hires and terminations dates?
	-- creating a view of each year's employee change
	DROP VIEW IF EXISTS employee_change;
    CREATE VIEW employee_change AS
		SELECT 
			term_year AS year,
			(CASE WHEN hire_year IS NULL THEN 0 ELSE hires END) AS hires,
			terminations,
			((CASE WHEN hire_year IS NULL THEN 0 ELSE hires END) - terminations) AS employee_net_change,
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
	
    SELECT *
    FROM employee_change
    ORDER BY year;
    
----------------------

-- 12. What is the average tenure with the company for current employees, terminated employees, and all employees?
	SELECT *
    FROM (
		--  average tenure of current employees
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
		--  average tenure of all employees
	JOIN (
        SELECT
			ROUND(AVG(years_worked), 1) AS overall_average_tenure
		FROM employees) sq3;
        
----------------------
        
-- 13. Which terminated employees have worked the greatest number of years?
	-- creating a view of terminated employees
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
				WHERE termination_date IS NOT NULL) AS avg_terminated_tenure
		FROM employees e
		JOIN dept_emp de 
			ON e.emp_no = de.emp_no 
			AND e.termination_date = de.to_date
		JOIN departments d 
			ON de.dept_no = d.dept_no
		LEFT JOIN salaries s 
			ON e.emp_no = s.emp_no
			AND e.termination_date = s.to_date
			AND s.from_date = (SELECT MAX(from_date) FROM salaries WHERE emp_no = e.emp_no)
		LEFT JOIN titles t 
			ON e.emp_no = t.emp_no
			AND de.to_date = t.to_date
			AND t.from_date = (SELECT MAX(from_date) FROM titles WHERE emp_no = e.emp_no)
		WHERE termination_date IS NOT NULL
		ORDER BY e.emp_no ) AS subquery;
	
    -- finding the employees who have worked the longest 
    SELECT *
    FROM employees_terminated
    ORDER BY years_worked DESC;

----------------------

-- 14. Which departments have the greatest difference in tenure from terminated employees compared to current employees?
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
		GROUP BY dept_name ) AS terminated_tenure
    JOIN (
	-- average years worked per department of current employees
		SELECT 
			d.dept_no,
			d.dept_name, 
			ROUND(AVG(years_worked), 2) AS dept_avg_tenure
		FROM employees e
					-- subquery to select employee's latest department dates
			JOIN (	SELECT emp_no, MAX(from_date) AS max_from_date, MAX(to_date) AS max_to_date
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
		GROUP BY dept_name ) AS overall_tenure
	ON terminated_tenure.dept_no = overall_tenure.dept_no
	ORDER BY tenure_difference DESC;
    
----------------------

-- 15. How many employees have worked 10 or more years with the company?
	SELECT *,
		ROUND((tenured_employees / total_employees) * 100, 1) AS percent_of_total
	FROM (
    SELECT 
		COUNT(*) AS tenured_employees,
			(SELECT 
				COUNT(*)
			FROM employees) AS total_employees
    FROM employees
    WHERE years_worked >= 10) subquery;
    
----------------------

-- 16. What is the distribution of terminated employees across departments?
	SELECT
		last_department,
        COUNT(emp_no) AS num_of_employees
    FROM employees_terminated
    GROUP BY last_department
    ORDER BY num_of_employees DESC;

----------------------

-- 17. What is the distribution and average salary of current employees across job titles?
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
    
---------------------- 

-- 18. What is the average salary per department for current employees?
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

---------------------- 

-- 19. How does the average salary of each department compare to the overall average salary and how does each gender's average salary compare to the department average salary for current employees?
	SELECT 
		dept_no,
        dept_name,
        overall_avg_salary,
        dept_avg_salary,
		(dept_avg_salary - overall_avg_salary) AS dept_salary_difference,
        gender,
        dept_gender_avg_salary,
        (dept_gender_avg_salary - dept_avg_salary) AS gender_diff_from_dept_avg
	FROM(
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
    
----------------------

-- 20. How do the average salaries of all employees, current employees, and terminated employees compare?
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

----------------------

-- 21. How many current employees per department are paid under the department's average salary?
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
	
    SELECT 
		dept_name,
        dept_avg_salary,
        count(emp_no) AS emp_count
    FROM emp_salary_comparison
    WHERE current_salary_comparison LIKE 'below%'
		AND salary_difference < 0
	GROUP BY dept_name
	ORDER BY emp_count DESC;
	
----------------------
   
-- 22. How many employees per gender are below their department's average salary?
	SELECT 
        emp_sal.gender,
        COUNT(*) AS num_of_under_avg_employees,
		total_working_employees,
        CONCAT(ROUND((COUNT(*) / total_working_employees) * 100, 2), '%') AS percent_emp_under_avg
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

----------------------

-- 23. How does changing departments impact an employee's salary? Which employee's have the greatest compensation increases?
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
			-- subquery returns an employee's salary and start date for the first department worked in
			(SELECT s.emp_no, s.salary, de.from_date, de.dept_no, d.dept_name
			 FROM salaries s
			 JOIN dept_emp de ON s.emp_no = de.emp_no
			 JOIN departments d ON de.dept_no = d.dept_no
				-- where the salary start date is the max date that is less than or equal to the end date of working in the first dept
			 WHERE s.from_date = (SELECT MAX(from_date) FROM salaries WHERE emp_no = s.emp_no AND from_date <= de.to_date)
			) AS dept1
		JOIN 
			-- subquery returns an employee's salary and start date for the second department worked in
			(SELECT s.emp_no, s.salary, de.from_date, de.dept_no, d.dept_name
			 FROM salaries s
			 JOIN dept_emp de ON s.emp_no = de.emp_no
			 JOIN departments d ON de.dept_no = d.dept_no
				-- where the salary start date is the min date that is greater than to the start date of working in the second dept
			 WHERE s.from_date = (SELECT MIN(from_date) FROM salaries WHERE emp_no = s.emp_no AND from_date >= de.from_date)
			) AS dept2
		ON 
			dept1.emp_no = dept2.emp_no
		AND 
			dept1.from_date < dept2.from_date;
	
    -- finding employees who have the greatest salary increase when transferring
    SELECT *
    FROM emp_dept_salary_change
    ORDER BY salary_difference DESC;

----------------------

-- 24. Which department has the greatest average salary increase when transferring into the department?
    SELECT 
		second_dept_name AS dept_transferred_in,
		ROUND(AVG(salary_difference), 2) AS avg_dept_salary_difference,
        COUNT(*) AS num_of_employees_transferred_in
    FROM emp_dept_salary_change
    GROUP BY second_dept_name
    ORDER BY avg_dept_salary_difference DESC;

----------------------

-- 25. How has employees' salary changed over time from being hired to their latest salary contract?
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
	
    -- finding the top employees who's salaries increase the most per years working
    SELECT *
    FROM emp_salary_years_worked
    ORDER BY salary_flux_per_years_worked DESC;

----------------------

-- 26. How do employees' salaries fluctuate between contracts over time?
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
    
----------------------
-- BUSINESS OPERATIONS STORED PROCEDURES -- 

-- 27. EMPLOYEE SALARY FUNCTION
-- creating a function to take in a user's input of an employee number and string and finds an employee's min, max, or salary difference from min and max salaries
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

	SELECT emp_salary(11356, 'min'), emp_salary(11356, 'max'), emp_salary(11356, 'diff');

----------------------

-- 28. EMPLOYEE CURRENT DEPARTMENT PROCEDURE
-- creating a stored prodecure that takes an employee number parameter and returns their department last worked in
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

	CALL employee_department(400000);

----------------------

-- 29. ALL EMPLOYEES INFORMATION VIEW
-- creating a view of all employees' info from all tables   
	DROP VIEW IF EXISTS employee_info;
	CREATE VIEW employee_info AS
		SELECT
			e.*,
			de.dept_no,
			d.dept_name,
			de.from_date AS deparment_start,
			de.to_date AS department_end,
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

----------------------

-- 30. CURRENT EMPLOYEES ONLY VIEW
	DROP VIEW IF EXISTS current_employees;
    CREATE VIEW current_employees AS 
		SELECT *
		FROM employee_info
		WHERE termination_date IS NULL;

----------------------

-- 31. TERMINATED EMPLOYEES ONLY VIEW
	DROP VIEW IF EXISTS terminated_employees;
    CREATE VIEW terminated_employees AS 
		SELECT *
		FROM employee_info
		WHERE termination_date IS NOT NULL;
        
----------------------


