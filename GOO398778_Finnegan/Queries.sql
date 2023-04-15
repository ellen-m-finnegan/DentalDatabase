USE mulcahyDentalPractice;

-- SELECT
    -- Select treatments with a cost above 100€
    SELECT * FROM treatment WHERE treatmentCost > 100;

-- INSERT
    -- Insert a new treatment
    INSERT INTO treatment VALUES ('Filling Replacement', '90.00'),

-- UPDATE
    -- Update the treatment cost
    UPDATE treatment SET treatmentCost= '55.00' WHERE treatmentName='Examination';

-- DELETE
    -- Delete treatment
    DELETE FROM treatment WHERE treatmentName='X-ray';

-- CREATE
    -- Create a view with people born after 1990
    CREATE VIEW Young_People AS SELECT patientNumber, patientFirstName, patientLastName, patientDOB FROM client WHERE patientDOB > '1990-01-01';