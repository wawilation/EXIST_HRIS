CREATE OR REPLACE FUNCTION fn_leave_allocation_request_egems_to_hydra() RETURNS VOID AS $$
DECLARE rec1 RECORD;
DECLARE rec2 RECORD;
DECLARE varID bigint;
DECLARE varID2 bigint;
DECLARE varDate1 timestamp;
DECLARE varDate2 timestamp;

BEGIN
    FOR rec1 IN SELECT 	
			linktable.id,			
			'N' AS deleted, --deleted
			NULL AS created_by, --created_by
			CAST(NULL AS timestamp with time zone) AS created_date, --created_date
			CAST(NULL AS timestamp with time zone) AS updated_date, --updated_date
			NULL AS updated_by, --updated_by,
			0 AS version, --version,	
			linktable.employee_number, --employee_number
			'Y' AS is_usable, --is_usable
			linktable.leaves_allocated AS leave_count, --leave_count
			CASE linktable.leave_type
				WHEN 'Vacation Leave' THEN 'VL'
				WHEN 'Maternity Leave' THEN 'ML'
				WHEN 'Sick Leave' THEN 'SL'
				WHEN 'Paternity Leave' THEN 'PL'
				WHEN 'Emergency Leave' THEN 'EL'
			END AS leave_type, --leave_type
			CASE linktable.date_to WHEN '2020-06-30' THEN '2020-12-31' ELSE linktable.date_to END AS leave_end_date, --leave_end_date
			linktable.date_from AS leave_start_date, --leave_start_date
			NULL AS linked_leave_type, --linked_leave_type
			'N' AS is_calendar_day, --is_calendar_day
			'N' AS is_continuous --is_continuous
		FROM records.dblink ('user=postgres password=postgres dbname=egemsdb', 'SELECT X.id, Y.employee_code, X.date_from, X.date_to, X.leave_type, X.leaves_allocated FROM employee_truancies X JOIN employees Y 					ON X.employee_id = Y.id;') AS
			linktable 
			(id bigint,
			employee_number character varying(255),
			date_from timestamp with time zone,
			date_to timestamp with time zone,
			leave_type character varying(255),
			leaves_allocated double precision) 
       LOOP

		INSERT INTO leaves.leave_allocation (id, deleted, created_by, created_date, updated_date, updated_by, version, employee_number, is_usable, leave_count, leave_type, leave_end_date, leave_start_date, linked_leave_type, is_calendar_day, is_continuous)
		VALUES (NEXTVAL('hibernate_sequence'), rec1.deleted, rec1.created_by, rec1.created_date, rec1.updated_date, rec1.updated_by, rec1.version, rec1.employee_number, rec1.is_usable, rec1.leave_count, rec1.leave_type, rec1.leave_end_date, rec1.leave_start_date, rec1.linked_leave_type, rec1.is_calendar_day, rec1.is_continuous) RETURNING id INTO varID;


		INSERT INTO leaves.leave_request (id, deleted, created_by, created_date, updated_date, updated_by, version, employee_number, leave_date, leave_period, responded_by, response_date, filing_status, 				leave_allocation, reason, remarks, parent_id, part_of_day, is_paid, timesheet_id) 	
		SELECT 	
			NEXTVAL('hibernate_sequence'),			
			'N', --deleted
			NULL, --created_by
			linktable.created_on AS created_date, --created_date
			linktable.updated_on AS updated_date, --updated_date
			NULL, --updated_by,
			0, --version,
			linktable.employee_number, --employee_number
			linktable.leave_date, --leave_date
			linktable.leave_unit, --leave_period
			linktable.responded_by, --responded_by
			linktable.responded_on, --response_date
			CASE linktable.response WHEN 'Approved' THEN 'APPROVED' ELSE linktable.response END, --filing_status
			varID, --linktable.employee_truancy_id, --leave_allocation
			linktable.details, --reason
			NULL, --remarks
			NULL, --parent_id
			CASE linktable.period WHEN 1 THEN 'AM' WHEN 2 THEN 'PM' WHEN 3 THEN 'WHOLE' END, --part_of_day
			'Y', --is_paid
			NULL --timesheet_id
		FROM records.dblink ('user=postgres password=postgres dbname=egemsdb', 
				'SELECT 
				X.employee_truancy_id, 
				X.leave_date, 
				X.leave_unit, 
				X.response,
				X.created_on,
				X.updated_on, 
				X.responded_on, 
				Z.employee_code, 
				(SELECT W.employee_code FROM employees W WHERE W.id = X.actual_responder_id) AS responded_by,	
				X.details, 
				X.period 
				FROM employee_truancy_details X JOIN employees Z 
					ON X.employee_id = Z.id
				WHERE X.response = ''Approved'' AND X.period <> 3 AND X.employee_truancy_id = ' || rec1.id || '') AS
			linktable 
			(employee_truancy_id bigint,
			leave_date timestamp with time zone,
			leave_unit double precision,
			response character varying(255),
			created_on timestamp with time zone,
			updated_on timestamp with time zone,
			responded_on timestamp with time zone,
			employee_number character varying(255),
			responded_by character varying(255),
			details character varying(255),
			period bigint);
		 
		
		FOR rec2 IN 
			 SELECT 	
				'N' AS deleted, --deleted
				NULL AS created_by, --created_by
				linktable.created_on AS created_date, --created_date
				linktable.updated_on AS updated_date, --updated_date
				NULL AS updated_by, --updated_by,
				0 AS version, --version,
				linktable.employee_number, --employee_number
				linktable.leave_date, --leave_date
				linktable.leave_unit AS leave_period, --leave_period
				linktable.responded_by, --responded_by
				linktable.responded_on AS response_date, --response_date
				CASE linktable.response WHEN 'Approved' THEN 'APPROVED' ELSE linktable.response END AS filing_status, --filing_status
				varID AS leave_allocation, --linktable.employee_truancy_id, --leave_allocation
				linktable.details AS reason, --reason
				NULL AS remarks, --remarks
				NULL AS parent_id, --parent_id
				CASE linktable.period WHEN 1 THEN 'AM' WHEN 2 THEN 'PM' WHEN 3 THEN 'WHOLE' END AS part_of_day, --part_of_day
				'Y' AS is_paid, --is_paid
				CAST(NULL AS bigint) AS timesheet_id, --timesheet_id
				linktable.optional_to_leave_date --optional_to_leave_date
			FROM records.dblink ('user=postgres password=postgres dbname=egemsdb', 
				'SELECT 
				X.employee_truancy_id, 
				X.leave_date, 
				X.leave_unit, 
				X.response,
				X.created_on,
				X.updated_on, 
				X.responded_on, 
				Z.employee_code, 
				(SELECT W.employee_code FROM employees W WHERE W.id = X.actual_responder_id) AS responded_by,	
				X.details, 
				X.period,
				X.optional_to_leave_date 
				FROM employee_truancy_details X JOIN employees Z 
					ON X.employee_id = Z.id
				WHERE X.response = ''Approved'' AND X.period = 3 AND X.employee_truancy_id = ' || rec1.id || '') AS
				linktable 
				(employee_truancy_id bigint,
				leave_date timestamp with time zone,
				leave_unit double precision,
				response character varying(255),
				created_on timestamp with time zone,
				updated_on timestamp with time zone,
				responded_on timestamp with time zone,
				employee_number character varying(255),
				responded_by character varying(255),
				details character varying(255),
				period bigint,
				optional_to_leave_date timestamp with time zone)     			

		LOOP
			varDate1 := rec2.leave_date;
			varDate2 := rec2.optional_to_leave_date;
			varID2 := NULL;

			WHILE varDate1 <= varDate2
			LOOP

			IF varID2 IS NULL THEN 
				INSERT INTO leaves.leave_request (id, deleted, created_by, created_date, updated_date, updated_by, version, employee_number, leave_date, leave_period, responded_by, response_date, 				filing_status, leave_allocation, reason, remarks, parent_id, part_of_day, is_paid, timesheet_id) VALUES (NEXTVAL('hibernate_sequence'), rec2.deleted, rec2.created_by, rec2.created_date, rec2.updated_date, rec2.updated_by, rec2.version, rec2.employee_number, varDate1, rec2.leave_period, rec2.responded_by, rec2.response_date, rec2.filing_status, rec2.leave_allocation, rec2.reason, rec2.remarks, varID2, rec2.part_of_day, rec2.is_paid, rec2.timesheet_id) RETURNING id INTO varID2;
			ELSE
				INSERT INTO leaves.leave_request (id, deleted, created_by, created_date, updated_date, updated_by, version, employee_number, leave_date, leave_period, responded_by, response_date, 				filing_status, leave_allocation, reason, remarks, parent_id, part_of_day, is_paid, timesheet_id) VALUES (NEXTVAL('hibernate_sequence'), rec2.deleted, rec2.created_by, rec2.created_date, rec2.updated_date, rec2.updated_by, rec2.version, rec2.employee_number, varDate1, rec2.leave_period, rec2.responded_by, rec2.response_date, rec2.filing_status, rec2.leave_allocation, rec2.reason, rec2.remarks, varID2, rec2.part_of_day, rec2.is_paid, rec2.timesheet_id);
			END IF;

				--RAISE NOTICE 'varDate1: %', varDate1;	
				varDate1 = varDate1 + INTERVAL '1 day';
							
			END LOOP;
		END LOOP;
    END LOOP;
	--EXCEPTION WHEN OTHERS THEN RAISE NOTICE '% %', SQLSTATE, SQLERRM;
END;
$$ LANGUAGE plpgsql;
