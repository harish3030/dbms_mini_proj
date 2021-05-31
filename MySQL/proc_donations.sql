DROP PROCEDURE IF EXISTS UPDATE_DONATIONS;
DELIMITER $$
CREATE PROCEDURE UPDATE_DONATIONS
(IN did INT,IN bid INT,IN units INT,IN comp varchar(255))
BEGIN
    DECLARE b_type varchar(20);
    DECLARE d_date date;
    DECLARE u_id int;
    UPDATE Donations 
    SET Status="Done"
    WHERE DonationID=did;

    SELECT date_donation,UserID into d_date,u_id FROM Donations where DonationID=did;
    
    UPDATE health_history    
    SET last_donated=d_date
    where UserID=u_id; 

    SELECT blood_type INTO b_type FROM HEALTH_HISTORY
    INNER JOIN User USING(UserID)
    WHERE UserID=u_id;

    INSERT INTO Blood Values
    (
        bid,did,b_type,comp,units
    );
END 
$$
DELIMITER ;

