CREATE OR REPLACE FUNCTION fn_employee_egems_to_hydra() RETURNS VOID AS $$

BEGIN

		INSERT INTO records.employee (id, deleted, created_by, created_date, updated_date, updated_by, version, city, country, address_line_1, address_line_2, province, zipcode, 				birth_date, birth_place, date_hired, date_regularized, email_address, employee_number, employment_status, gender, landline_number, mobile_number, family_name, given_name, maiden_name, middle_name, nickname, suffix, branch_code, department_code, job_designation_code, job_level_code, profile_picture, shift_schedule_id, key_card_identifier, birth_day, birth_month, birth_year) 	
		SELECT 	
			NEXTVAL('hibernate_sequence'),			
			'N' AS deleted, --deleted
			NULL, --created_by
			NULL, --created_date			
			NULL, --updated_date
			NULL, --updated_by
			0, --version
			NULL, --city
			NULL, --country
			NULL, --address_line_1 			
			NULL, --address_line_2
			NULL, --province
			NULL, --zipcode
			linktable.birthdate,
			linktable.birthplace,
			linktable.date_hired,
			linktable.date_regularized,
			linktable.email,
			linktable.employee_code,
			CASE linktable.employment_status WHEN 'Active' THEN 'REGULAR' WHEN 'Resigned' THEN 'RESIGNED' WHEN 'Management' THEN 'REGULAR' WHEN 'Active-Hired Files' THEN 'RESIGNED' ELSE 				linktable.employment_status END AS employment_status,
			CASE linktable.gender WHEN 'M' THEN 'MALE' WHEN 'F' THEN 'FEMALE' ELSE linktable.gender END AS gender,
			NULL, --landline_number
			NULL, --mobile_number
			linktable.last_name,
			linktable.first_name,
			linktable.maiden_name,
			linktable.middle_name,
			NULL, --nickname
			NULL, --suffix
			'MNL', --branch_code
			'ENG', --department_code
			linktable.code,
			linktable.level,
			NULL, --profile_picture
			CASE WHEN linktable.level IN ('L1','L2','L3','L4') THEN 1 wHEN linktable.level IN ('L5','L6') THEN 2 WHEN linktable.level = 'TM' THEN 3 ELSE 0 END, --shift_schedule_id
			NULL, --key_card_identifier,
			EXTRACT(DAY FROM linktable.birthdate), --birth_day
			EXTRACT(MONTH FROM linktable.birthdate), --birth_month
			EXTRACT(YEAR FROM linktable.birthdate) --birth_year
		FROM dblink ('user=postgres password=postgres dbname=egemsdb', 'SELECT X.employee_code, X.first_name, X.last_name, X.middle_name, X.maiden_name, X.gender, X.birthdate, X.birthplace, X.email, 					X.date_hired, X.employment_status, X.date_regularized, X.current_job_position_id, Y.code, Y.level FROM employees X LEFT JOIN job_positions Y ON X.current_job_position_id = Y.id') 				AS
			linktable 
			(employee_code character varying(20), 
			--title character varying(10), 
			first_name character varying(50), 
			last_name character varying(50), 
			middle_name character varying(50), 
			--full_name character varying(255), 
			maiden_name character varying(255), 
			--other_name character varying(255), 
			gender character(1) ,             
			birthdate timestamp with time zone,
			birthplace character varying(255), 
			email character varying(255), 
			--shift_schedule_id bigint, 
			--employee_supervisor_id bigint, 
			--current_department_id bigint, 
			date_hired timestamp with time zone,
			employment_status character varying(255),
			--created_on timestamp with time zone,
			--created_by bigint,
			--updated_on timestamp with time zone,
			--updated_by bigint,
			--branch_id bigint,
			date_regularized timestamp with time zone,
			--employee_project_manager_id bigint,
			--is_tl_authorized boolean)
			current_job_position_id bigint,			
			code character varying(10),
			level character varying(10));

	--EXCEPTION WHEN OTHERS THEN RAISE NOTICE '% %', SQLSTATE, SQLERRM;
END;
$$ LANGUAGE plpgsql;
