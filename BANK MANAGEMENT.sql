USE WORKSHOP_PROJECT
-------------------------------TABLES----------------------
----account opening---------
CREATE TABLE ACCOUNT_OPENING(
AC_DATE DATE,
ACCOUNT_TYPE VARCHAR(20),
ACCOUNT_HOLDER_NAME VARCHAR(20),
DOB DATE,
ADHAR_NUMBER BIGINT,
MOBILE_NUMBER BIGINT,
OPENING_BALANCE BIGINT,
ADDRESS VARCHAR(20),
KYC_STATUS VARCHAR(20) DEFAULT 'PENDING'
)

INSERT INTO ACCOUNT_OPENING
(AC_DATE,ACCOUNT_TYPE,ACCOUNT_HOLDER_NAME,DOB,ADHAR_NUMBER,MOBILE_NUMBER,OPENING_BALANCE,ADDRESS)
VALUES 
('2024-07-23','Saving','Ananya','2001-11-04',453623456543,9884893857,1000,'New Delhi'),
('2024-07-24','Saving','Neha','2003-11-04',409785647893,9847538567,2000,'Mumbai')

---------Bank---------------
create table bank (
ACC_Number INT IDENTITY(100001,1) ,
Acc_Type VARCHAR(20),
Acc_Opening_Data DATE,
Current_Balance BIGINT
)

----------account holder details------------
create table account_holder(
Acc_numbe INT IDENTITY(100001,1) ,
Acc_holder_name varchar(20),
DOB date,
aadhar_number BIGINT,
mobile_number BIGINT,
full_addredd varchar(20)
)
-----------transactions------
create table transaction_details (
acc_number INT,
payment_type varchar(20),
trans_amount BIGINT,
trans_date date
)
-------------------------trigger----------------------------------
create trigger tig_update_acount_opening
on account_opening 
after update 
as
begin 
	declare @status_before varchar(20)
	declare @status_after varchar(20)
	select @status_before=KYC_STATUS from deleted
	select @status_after=KYC_STATUS from inserted
	if @status_before='pending' AND @status_after='approved'
		begin
		declare @acctyp varchar(20)
		declare @openbal BIGINT
		declare @name varchar(20)
		declare @DOB DATE
		declare @adharNo BIGINT
		declare @mobileNo BIGINT
		declare @add varchar(20)
		select @acctyp=Account_type,@openbal=OPENING_BALANCE FROM INSERTED
		select @name=ACCOUNT_HOLDER_NAME,@DOB=DOB,@adharNo=ADHAR_NUMBER,@mobileNo=MOBILE_NUMBER,@add=ADDRESS FROM INSERTED
		
		insert into bank(Acc_Type,Acc_Opening_Data,Current_Balance)
		values(@acctyp,getdate(),@openbal)
		
		insert into account_holder(Acc_holder_name,DOB,aadhar_number,mobile_number,full_addredd)
		values(@name,@DOB,@adharNo,@mobileNo,@add)
	end
end

update ACCOUNT_OPENING
set KYC_STATUS='approved'
where ADHAR_NUMBER =453623456543
select * from bank
select * from account_holder

------------------procedure--------------
CREATE procedure sp_credit_into 
@acountNumber BIGINT,
@transaction_ammount BIGINT
as begin
	IF (@acountNumber NOT IN (select ACC_Number from bank))  
		BEGIN
			PRINT 'account number doesnt exist.';
			RETURN;  
    END
	begin transaction 
	insert into transaction_details(acc_number,payment_type,trans_amount,trans_date)
	values
	(@acountNumber,'Credit',@transaction_ammount,getdate())
	declare @sal bigint
	declare @newsal bigint

	select @sal=Current_Balance from bank where ACC_Number=@acountNumber;

	set @newsal=@sal+@transaction_ammount

	update bank 
	set Current_Balance=@newsal
	where ACC_Number=@acountNumber
	commit
end

create procedure sp_debit_into 
@acountNumber BIGINT,
@transaction_ammount BIGINT
as begin
	IF (@acountNumber NOT IN (select ACC_Number from bank))  
		BEGIN
			PRINT 'account number doesnt exist.';
			RETURN;  
    END
	begin transaction 
	insert into transaction_details(acc_number,payment_type,trans_amount,trans_date)
	values
	(@acountNumber,'debit',@transaction_ammount,getdate())
	declare @sal bigint
	declare @newsal bigint

	select @sal=Current_Balance from bank where ACC_Number=@acountNumber;

	set @newsal=@sal-@transaction_ammount
	if(@newsal<0)
		rollback;
		return;
	update bank 
	set Current_Balance=@newsal
	where ACC_Number=@acountNumber
	commit
end

sp_credit_into 100001,5000
select * from transaction_details

CREATE procedure sp_give_passbook 
@account_number BIGINT,
@month INT
as begin
	IF (@account_number NOT IN (select ACC_Number from bank))  
		BEGIN
			PRINT 'account number doesnt exist.';
			RETURN;  
    END
	declare @tardate DATE
	set @tardate =DATEADD(MONTH,@month*-1,getdate() )
	select * from transaction_details where acc_number=@account_number and trans_date>@tardate
	order by trans_date
end

sp_give_passbook 100001,4