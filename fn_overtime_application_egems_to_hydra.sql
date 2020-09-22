CREATE OR REPLACE FUNCTION fn_overtime_application_egems_to_hydra() RETURNS VOID AS $$
BEGIN
		INSERT INTO timekeeping.overtime_application (deleted, created_by, created_date, updated_date, updated_by, version, responder, employee_number, minutes_applied, minutes_approved, status, 			overtime_credits_id, timesheet_id, reason, minutes_eligible, remarks) 	
		SELECT 	
			--NEXTVAL('hibernate_sequence'),			
			'N', --deleted
			NULL, --created_by
			linktable.date_filed, --created_date
			linktable.updated_on, --updated_date
			NULL, --updated_by
			0, --version
			NULL, --responder
			linktable.employee_number, --employee_number
			linktable.overtime_minutes_applied, --minutes_applied
			linktable.duration_approved, --minutes_approved
			'APPROVED' AS status, --status,
			NULL, --overtime_credits_id,
			A.id, --timesheet_id
			linktable.work_details, --reason
			linktable.duration, --minutes_eligible
			NULL --remarks
		FROM dblink ('user=postgres password=postgres dbname=egemsdb_temp', 'SELECT X.date_of_overtime, Z.employee_code, X.work_details, X.date_filed, X.duration, X.duration_approved, 				Y.overtime_minutes_applied, X.updated_on FROM employee_overtimes X JOIN employee_timesheets Y on X.employee_id = Y.employee_id AND X.date_of_overtime = Y.date 
			JOIN employees Z ON Y.employee_id = Z.id WHERE X.status = ''Approved''') AS
			linktable 
			(date_of_overtime timestamp with time zone,
			employee_number character varying(255),
			work_details character varying(255),
			date_filed timestamp with time zone,
			duration bigint,
			duration_approved bigint,
			overtime_minutes_applied bigint,
			updated_on timestamp with time zone
			)
		JOIN timekeeping.timesheet A ON A.date = linktable.date_of_overtime AND A.employee_number = linktable.employee_number;

	--EXCEPTION WHEN OTHERS THEN RAISE NOTICE '% %', SQLSTATE, SQLERRM;
END;
$$ LANGUAGE plpgsql;
