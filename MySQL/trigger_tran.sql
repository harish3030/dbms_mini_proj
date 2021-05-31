DROP TRIGGER IF EXISTS update_avail;
DELIMITER $$
CREATE TRIGGER update_avail
AFTER UPDATE  ON Requests 
FOR EACH ROW
BEGIN
    DECLARE l_date datetime;
    IF (New.status="Done") THEN
        SELECT NOW() INTO l_date;
        INSERT INTO TRANSACTIONS(RequestID,BloodBankID,blood_type,blood_component,blood_units,date_sent) VALUES
        (New.RequestID,New.BloodBankID,New.blood_type,New.blood_component,New.Units,l_date);
    END IF;
END $$
DELIMITER ;
    