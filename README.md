# Banking Loan Risk and Operations Analysis

**What can a bank's own records tell us about where it is losing money, where effort is being wasted, and where it could grow?**

This project answers that with SQL, using records from a bank with 3,000 customers, 4,200 accounts, 3,200 loan applications and 24,000 transactions across 15 branches. The findings are written up in a short report for non-technical readers, and the SQL behind every answer is included.

**Start here:** [read the report](report/Banking_Portfolio_Review.pdf)

---

## In plain words

Banks keep a lot of records: who their customers are, what accounts and loans they have, and every deposit, withdrawal and transfer. Hidden in those records are useful answers. Which loans are most likely to go unpaid? Which branches are overworked? Where do payments fail? Is the bank relying too much on a few big loans?

I asked eight questions like these and used SQL (the language for asking questions of a database) to find the answers. For each one, the report explains what I found and what I would suggest the bank do about it.

## The eight questions

1. **Loan defaults.** Which types of customers and loans are most likely to stop being repaid?
2. **Loan approvals.** Do all branches approve loans in a similar way, or do some say yes much more or less often than others?
3. **Staff workload.** How much work does each branch employee handle, and are some branches stretched while others are quiet?
4. **Busy and quiet periods.** Does the bank get busier at certain times of the year, and is it growing?
5. **Failed payments.** Where do transactions fail or get stuck, and how much money is held up?
6. **Reliance on big loans.** How much of the bank's lending depends on a few very large loans, products or branches?
7. **Growth opportunity.** Which customers keep money with the bank but have never taken a loan, and could be offered one?
8. **Dormant accounts.** Are accounts marked "Active" really being used?

## A few headline results

- About 7.7% of approved loans have defaulted, worth roughly 170 million. Education loans are the riskiest product.
- The biggest 10% of active loans hold more than a quarter of all the money lent, and every one of them is a Home or Business loan.
- About 3.6% of transactions fail or stay pending, and one branch (Nagpur City) is clearly worse than the rest.
- Nearly two in three accounts marked "Active" had no transaction in the last 90 days.
- 907 customers keep money with the bank but have no loan, which makes them a natural group to approach.

The full findings, with a suggestion for each question, are in the [report](report/Banking_Portfolio_Review.pdf).

## What is in this repository

| Folder | What it holds |
|---|---|
| `report/` | The plain-language report with findings and suggestions. Best place to start. |
| `sql/` | The SQL code. Each of the eight questions is saved as a reusable "view". |
| `data/` | The six data files used, plus the license that came with them. |

## About the data

The data is a public practice dataset from GitHub: [shoaib4752/FINANCE-DATA-ANALYSIS](https://github.com/shoaib4752/FINANCE-DATA-ANALYSIS), used under its MIT License (the license text is in `data/SOURCE_LICENSE.txt`). It is not confirmed to be real bank data and may be simulated, so the findings describe this dataset, not a real institution. The currency is not stated, so amounts are shown as plain figures.

## A few limits worth knowing

- Default figures use approved loans only, because a rejected application cannot default.
- Some groups are small. Where a result rests on a few loans, the report says so.
- The "Active accounts" check looks at the last 90 days of the data. Transactions in this dataset are sparse, so that window is strict.

---

## For technical readers

**Tables (6):** `customers`, `accounts`, `loans`, `transactions`, `employees`, `branches`.

**Techniques used:** inner, left, cross and anti-joins; common table expressions; window functions (`DENSE_RANK`, `NTILE`, `LAG`, running totals, `SUM() OVER ()`); conditional aggregation; `HAVING`; date functions; NULL handling; SQL views.

**Data preparation:** amounts were imported as text and converted to `DECIMAL`. Text sorts alphabetically, which silently gave wrong "top 10%" results until it was fixed.

**Choices made:**
- Loan risk uses approved loans. Exposure means active loans.
- Group comparisons use at least 30 loans or transactions.
- The "last 90 days" reference date is the last date in the data, not today's date.
- Bank-wide rates are total part divided by total whole, not an average of branch rates.

**To run it (MySQL 8+):**
1. Create a database and import the six CSV files from `data/`.
2. Convert the money columns to `DECIMAL`. Dates in `transactions` are text in `dd-mm-yyyy` format.
3. Run `sql/analysis_views.sql`.
4. Query any view, for example:
   ```sql
   SELECT * FROM v1_default_by_segment_loan_type ORDER BY Loan_Type, rank_in_loan_type;
   ```

---

Built by **[Your name]**. Feedback is welcome: [LinkedIn profile link]
