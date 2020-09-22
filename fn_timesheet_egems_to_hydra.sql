CREATE OR REPLACE FUNCTION fn_timesheet_egems_to_hydra() RETURNS VOID AS $$

BEGIN
		INSERT INTO timekeeping.timesheet (deleted, created_by, created_date, updated_date, updated_by, version, employee_number, time_in, time_out, minutes_late,
 		minutes_overtime, minutes_undertime, total_work_minutes, date, key_card_identifier, filed_overtime, status, valid, schedule_id) 	
		SELECT 	
			--NEXTVAL('hibernate_sequence'),
			'N', --deleted
			NULL, --created_by
			NULL, --created_date			
			NULL, --updated_date
			NULL, --updated_by
			0, --version
			linktable.employee_id, --employee_number
			linktable.time_in, --time_in
			linktable.time_out, --time_out,
			linktable.minutes_late, --minutes_late
			linktable.minutes_excess, --minutes_overtime
			linktable.minutes_undertime, --minutes_undertime
			linktable.duration, --total_work_minutes
			linktable.date, --date,
			NULL, --key_card_identifier
			linktable.is_excess_minutes_applied, --filed_overtime
			'OK', --status
			'Y', --valid
			NULL --schedule_id
		FROM dblink ('user=postgres password=postgres dbname=egemsdb_temp', 'SELECT date, time_in, time_out, duration, minutes_late, minutes_undertime, minutes_excess, is_excess_minutes_applied,
				Y.employee_code FROM employee_timesheets X JOIN employees Y on X.employee_id = Y.id') AS
			linktable 
			(date timestamp with time zone,
			time_in timestamp with time zone,
			time_out timestamp with time zone,
			duration bigint,
			minutes_late bigint,
			minutes_undertime bigint,
			minutes_excess bigint,
			is_excess_minutes_applied bigint,
			employee_id character varying(20));


	--EXCEPTION WHEN OTHERS THEN RAISE NOTICE '% %', SQLSTATE, SQLERRM;
END;
$$ LANGUAGE plpgsql;
