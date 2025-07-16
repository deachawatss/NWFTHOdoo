-- Add employee_id column if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name='hr_employee' AND column_name='employee_id') THEN
        ALTER TABLE hr_employee ADD COLUMN employee_id varchar;
        -- Add index for better performance
        CREATE INDEX hr_employee_employee_id_idx ON hr_employee(employee_id);
    END IF;
END$$; 