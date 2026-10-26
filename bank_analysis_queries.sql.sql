select * from accounts;
select * from branches;

select * from  customber
limit 50 ;

select * from employees;

select * from loans
limit 50;
select * from transations;

select distinct Loan_Type
from loans;
select distinct Customer_Segment
from customber;


create view defaulted_amount as (
WITH segment_stats AS (
    SELECT
        c.Customer_Segment,
        l.Loan_Type,
        COUNT(*)                                     AS total_loans,
        SUM(l.Loan_Status = 'Defaulted')             AS defaulted_loans,
        ROUND(SUM(l.Loan_Amount), 2)                 AS total_loan_amount,
        ROUND(SUM(CASE WHEN l.Loan_Status = 'Defaulted'
                       THEN l.Loan_Amount ELSE 0 END), 2) AS defaulted_amount
    FROM loans l
    JOIN customber c  ON c.Customer_ID = l.Customer_ID
    WHERE l.Approval_Status = 'Approved'
    GROUP BY c.Customer_Segment, l.Loan_Type
    HAVING COUNT(*) >= 30
),
rates AS (
    SELECT *,
        ROUND(100.0 * defaulted_loans  / total_loans, 2)                  AS default_rate_pct,
        ROUND(100.0 * defaulted_amount / NULLIF(total_loan_amount, 0), 2) AS default_amount_pct
    FROM segment_stats
)
SELECT *,
    DENSE_RANK() OVER (PARTITION BY Loan_Type ORDER BY default_rate_pct DESC) AS rank_in_loan_type
FROM rates
);


select * from branches
limit 50;
select * from customber
limit 50;
select * from loans
limit 50;
select count(Employee_ID) from employees
where Branch_ID='BR001'
limit 50;

create view approve_rate as(
WITH branch_seg_stats AS (
    SELECT
        l.Branch_ID,
        c.Customer_Segment,
        COUNT(*)                            AS total_applications,
        SUM(l.Approval_Status = 'Approved') AS approved
    FROM loans l
    JOIN customber c
        ON c.Customer_ID = l.Customer_ID
    GROUP BY l.Branch_ID, c.Customer_Segment
)
SELECT
    Branch_ID,
    Customer_Segment,
    total_applications,
    approved,
    ROUND(100.0 * approved / total_applications, 2) AS approval_rate_pct,
    ROUND(100.0 * SUM(approved) OVER () / SUM(total_applications) OVER (), 2) AS bank_rate_pct,
    ROUND(
        100.0 * approved / total_applications
        - 100.0 * SUM(approved) OVER () / SUM(total_applications) OVER ()
    , 2) AS diff_vs_bank_pts
FROM branch_seg_stats
ORDER BY Branch_ID, Customer_Segment
); 


select * from employees;
create view bes_emp_branch  as (
with employess_perbranch as (
select Branch_ID,
sum(
case  
    when Employment_Status='Active'
    then 1
    else 0
    end 
    )employees_perbranch
    from employees 
group by Branch_ID 
),
amount_perbranch as (
select t.Branch_ID,
round(sum(
         case 
         when Transaction_Status='Completed' then amount
         else 0 
         end 
         ),2) as branch_total_amount
   
       from transations t
       group by  Branch_ID
),
emp_amount as (
select e.employees_perbranch,a.branch_total_amount,e.Branch_ID,
round(branch_total_amount/e.employees_perbranch,2) as emp_amountperbranch

from employess_perbranch e
 inner join amount_perbranch a
 using(Branch_ID)
 )
 select e.Branch_ID,e.employees_perbranch,a.branch_total_amount,emp.emp_amountperbranch,
 dense_rank() over( order by emp.emp_amountperbranch desc)employees
 from employess_perbranch e
 inner join amount_perbranch a
 using(Branch_ID)
 inner join emp_amount emp
 using(Branch_ID)
 );
  select * from transations;

create view year_over_yearcompare as (
with transation_mo as (
select
month(str_to_date(Transaction_Date,'%d-%m-%Y'))as transation_month ,
year(str_to_date(Transaction_Date,'%d-%m-%Y'))as transation_year,

round(sum(
          case when Transaction_Status='Completed'
          then Amount
          else 0
          end
) ,2)as total_amountoftran,
count(
      case when Transaction_Status='Completed'
      then 1
     
      end) as total_transations

from transations
 group by  transation_month,transation_year
order by transation_month
),
total_lad as(
select *,
lag(total_amountoftran,12)over(order by transation_year,transation_month) asame_mo_last_y
from transation_mo 
)
select 
transation_year,transation_month,total_amountoftran,total_transations,
    ROUND(
    100.0 * (total_amountoftran- asame_mo_last_y)
    / NULLIF(asame_mo_last_y, 0),
    2
 )AS yoy_pct
     from total_lad
);
select * from loans;
select * from transations;

create view failed_tran as(
WITH cell AS (
    SELECT
        Branch_ID,
        method,
        COUNT(*)                                          AS total_txns,
        SUM(Transaction_Status IN ('Failed','Pending'))   AS bad_txns,
        SUM(Transaction_Status = 'Failed')                AS failed_txns,
        SUM(Transaction_Status = 'Pending')               AS pending_txns,
        ROUND(SUM(CASE WHEN Transaction_Status IN ('Failed','Pending')
                       THEN Amount ELSE 0 END), 2)        AS stuck_amount
    FROM transations
    GROUP BY Branch_ID, method
    HAVING COUNT(*) >= 30
),
bank AS (
    SELECT
        100.0 * SUM(Transaction_Status IN ('Failed','Pending')) / COUNT(*) AS bank_rate_pct,
        SUM(CASE WHEN Transaction_Status IN ('Failed','Pending')
                 THEN Amount ELSE 0 END)                                   AS total_stuck
    FROM transations
)
SELECT
    c.Branch_ID,
    c.method,
    c.total_txns,
    c.failed_txns,
    c.pending_txns,
    ROUND(100.0 * c.bad_txns / c.total_txns, 2)                      AS fail_pending_rate_pct,
    ROUND(b.bank_rate_pct, 2)                                        AS bank_rate_pct,
    ROUNbes_emp_branchD(100.0 * c.bad_txns / c.total_txns -ank_rate_pc bbt, 2)    AS diff_vs_bank_pts,
    c.stuck_amount,
    ROUND(100.0 * c.stuck_amount / b.total_stuck, 2)                 AS pct_of_all_stuck_amount,
    DENSE_RANK() OVER (ORDER BY c.bad_txns / c.total_txns DESC)      AS risk_rank
FROM cell c
CROSS JOIN bank b
ORDER BY risk_rank
);

select * from loans
limit 100;
create view top_10customber_analysis as (
with top10 as (
select loan_id,Branch_ID,Loan_Type,Loan_Amount,
-- round(sum(case when Loan_Status='active' then Loan_Amount end),2)as active_loans,
ntile(10) over(order by Loan_Amount desc) top10per_customer
from loans
where Loan_Status='active'
)

select branch_id,Loan_Type,

sum(loan_amount) total_amount ,
count(loan_amount) total_no_ofamount,

 round(100.0*(sum(case when top10per_customer=1 then Loan_Amount else 0 end))/sum(Loan_Amount),2) as top10_share_pct
-- round(sum(case when top10per_customer=1 then Loan_Amount end),2)
from  top10
group by  branch_id,Loan_Type
) ;
alter table loans
modify loan_amount int(25);
select * from loans limit 100;
select * from customber limit 100;
select * from accounts ;
 
 create view without_loans_cus as (
WITH accounts_active AS (
    SELECT Customer_ID, 
    round(sum(Current_Balance),2) AS total_balance
    FROM accounts
    WHERE Account_Status = 'Active'
    GROUP BY Customer_ID
),
targets AS (
    SELECT a.Customer_ID, 
    c.Customer_Segment, a.total_balance
    
    FROM accounts_active a
    
    JOIN customber c 
    ON c.Customer_ID = a.Customer_ID
    LEFT JOIN loans l
    
        ON l.Customer_ID = a.Customer_ID
       AND l.Approval_Status = 'Approved'
       
    WHERE l.Customer_ID IS NULL
)
SELECT Customer_Segment, Customer_ID, total_balance,
       DENSE_RANK() OVER (PARTITION BY Customer_Segment
                          ORDER BY total_balance DESC) AS rank_in_segment
                          
FROM targets
ORDER BY Customer_Segment, rank_in_segment
 
 )  ;
 
 select * from accounts
 limit 100;
 select * from transations
 ;
 create view active_customers as (
 with recent_transation as (
 select Customer_ID,
 max(
 case when Transaction_Status='Completed' then (str_to_date((Transaction_Date),'%d-%m-%Y')) end
 ) as recent_tran ,
 count(*) as active_accounts

 from transations
 where Transaction_Status='Completed'
 group by Customer_ID
 
 ),
 active_customer as (
 select t.*,
 a.Account_Type
 
 from recent_transation t
 left join accounts a 
 on
 a.Customer_ID=t.Customer_ID
 where recent_tran
 between(date_sub('2025-12-31', interval 90 day))
 and '2025-12-31'
 )

 select Customer_ID,Account_Type, max(recent_tran) resend_transation,
 count(active_accounts) over() as total_activeaccounts

from active_customer
 group by  Customer_ID,Account_Type
 order by Customer_ID asc
 
 )
 