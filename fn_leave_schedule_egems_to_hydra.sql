CREATE OR REPLACE FUNCTION fn_leave_schedule_egems_to_hydra() RETURNS VOID AS $$
DECLARE rec1 RECORD;
DECLARE rec2 RECORD;
--DECLARE varID bigint;
DECLARE intCounter int;

BEGIN
	intCounter := 0;
	
	FOR rec1 IN
		SELECT 	
			'N' AS deleted, --deleted
			NULL AS created_by, --created_by
			CAST(NULL AS timestamp with time zone) AS created_date, --created_date			
			CAST(NULL AS timestamp with time zone) AS updated_date, --updated_date
			NULL AS updated_by, --updated_by
			0 AS version, --version
			'Y' AS is_active, --is_active
			linktable.employee_code AS employee_number,
			linktable.date_hired
		FROM records.dblink ('user=postgres password=postgres dbname=egemsdb', 'SELECT employee_code, date_hired FROM employees') AS
			linktable 
			(employee_code character varying(20), 
			date_hired timestamp with time zone)


	LOOP
		INSERT INTO leaves.leave_schedule (deleted, created_by, created_date, updated_date, updated_by, version, is_active, employee_number, date_hired) 	
		VALUES (rec1.deleted, rec1.created_by, rec1.created_date, rec1.updated_date, rec1.updated_by, rec1.version, rec1.is_active, rec1.employee_number, rec1.date_hired); --RETURNING id INTO varID; 		
			

	END LOOP;

	FOR rec2 IN
		
		SELECT id FROM leaves.leave_schedule

	LOOP
		WHILE intCounter < 8
		LOOP
			INSERT INTO leaves.join_leave_schedule_x_leave_policy (leave_schedule_id, policy_id) 
			SELECT rec2.id, MIN(id) + intCounter FROM leaves.leave_policy;

			IF intCounter < 8 THEN			
				intCounter := intCounter + 1;
			END IF;
		END LOOP;
		intCounter := 0;
	END LOOP;



	--EXCEPTION WHEN OTHERS THEN RAISE NOTICE '% %', SQLSTATE, SQLERRM;

END;
$$ LANGUAGE plpgsql;
