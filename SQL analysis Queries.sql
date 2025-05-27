USE BankingAnalytics;


--========================================================== Customer Analysis Queries

-- 1. Count total active customers (those with at least one account)
SELECT COUNT(DISTINCT c.customer_id) AS total_active_customers
FROM Customers c
JOIN Accounts a ON c.customer_id = a.customer_id;

-- 2. Monthly new customers (group by year and month of JoinDate)
SELECT FORMAT(JoinDate, 'yyyy-MM') AS month, COUNT(*) AS new_customers
FROM Customers
GROUP BY FORMAT(JoinDate, 'yyyy-MM')
ORDER BY month;

-- 3. Average number of accounts per customer
SELECT AVG(account_count*1.0) AS avg_accounts_per_customer
FROM (
    SELECT customer_id, COUNT(*) AS account_count
    FROM Accounts
    GROUP BY customer_id
) AS sub;

-- 4. Identify potential churn risks (customers with no transactions in the last 6 months)
SELECT c.customer_id, c.FirstName, c.LastName
FROM Customers c
LEFT JOIN Accounts a ON c.customer_id = a.customer_id
LEFT JOIN Transactions t ON a.AccountID = t.AccountID 
    AND t.TransactionDate >= DATEADD(MONTH, -6, GETDATE())
GROUP BY c.customer_id, c.FirstName, c.LastName
HAVING COUNT(t.TransactionID) = 0;




--========================================================== Account Analysis Queries

-- 1. Total balance by account type
SELECT AccountType, SUM(balance) AS total_balance
FROM Accounts
GROUP BY AccountType;

-- 2. Average balance per customer (across all their accounts)
SELECT AVG(customer_balance*1.0) AS avg_balance_per_customer
FROM (
    SELECT customer_id, SUM(balance) AS customer_balance
    FROM Accounts
    GROUP BY customer_id
) AS sub;

-- 3. Identify dormant accounts (no transactions in the last 6 months)
SELECT a.AccountID, a.customer_id, a.AccountType, a.balance, a.CreatedDate
FROM Accounts a
LEFT JOIN Transactions t ON a.AccountID = t.AccountID 
    AND t.TransactionDate >= DATEADD(MONTH, -6, GETDATE())
GROUP BY a.AccountID, a.customer_id, a.AccountType, a.balance, a.CreatedDate
HAVING COUNT(t.TransactionID) = 0;

-- 4. Account age vs balance (for correlation analysis externally)
SELECT AccountID, balance, DATEDIFF(MONTH, CreatedDate, GETDATE()) AS account_age_months
FROM Accounts;







--========================================================== Transaction Analysis Queries

-- 1. Monthly transaction trends (count and total amount)
SELECT FORMAT(TransactionDate, 'yyyy-MM') AS month, 
       COUNT(*) AS transactions_count, 
       round(SUM(amount),2) AS total_amount
FROM Transactions
GROUP BY FORMAT(TransactionDate, 'yyyy-MM')
ORDER BY month;

-- 2. Top transaction types by count and total amount
SELECT TransactionType, COUNT(*) AS count, round(SUM(amount),2) AS total_amount
FROM Transactions
GROUP BY TransactionType
ORDER BY total_amount DESC;

-- 3. Average transaction value by account type
SELECT a.AccountType, round(AVG(t.amount*1.0),2) AS avg_transaction_value
FROM Transactions t
JOIN Accounts a ON t.AccountID = a.AccountID
GROUP BY a.AccountType;




--========================================================== Loan Portfolio Analysis Queries

-- 1. Total loan amount disbursed by loan type
SELECT LoanType, SUM(LoanAmount) AS total_loan_amount
FROM Loans
GROUP BY LoanType;

-- 2. Average interest rate per loan type
SELECT LoanType, AVG(InterestRate*1.0) AS avg_interest_rate
FROM Loans
GROUP BY LoanType;

-- 3. Loans maturing this year (based on end_date)
SELECT LoanType, COUNT(*) AS loans_maturing_this_year
FROM Loans
WHERE YEAR(LoanEndDate) = YEAR(GETDATE())
GROUP BY LoanType;





--========================================================== Card Analysis Queries

-- 1. Monthly card issuance trends (group by year and month of issue_date)
SELECT FORMAT(IssuedDate, 'yyyy-MM') AS month, COUNT(*) AS cards_issued
FROM Cards
GROUP BY FORMAT(IssuedDate, 'yyyy-MM')
ORDER BY month;

-- 2. Active vs expired cards (based on ExpirationDate compared to current date)
SELECT 
    SUM(CASE WHEN ExpirationDate >= GETDATE() THEN 1 ELSE 0 END) AS active_cards,
    SUM(CASE WHEN ExpirationDate < GETDATE() THEN 1 ELSE 0 END) AS expired_cards
FROM Cards;

-- 3. Card type distribution (count of each card type)
SELECT CardType, COUNT(*) AS count
FROM Cards
GROUP BY CardType;

-- 4. Average number of cards per customer by card type
SELECT CardType, AVG(card_count*1.0) AS avg_cards_per_customer
FROM (
    SELECT CustomerID, CardType, COUNT(*) AS card_count
    FROM Cards
    GROUP BY CustomerID, CardType
) AS sub
GROUP BY CardType;









--========================================================== Customer Support Insights Queries

-- 1. Total number of support calls
SELECT COUNT(*) AS total_support_calls
FROM SupportCalls;

-- 2. Most frequent issue type (top issue category)
SELECT TOP 1 IssueType
FROM SupportCalls
GROUP BY IssueType
ORDER BY COUNT(*) DESC;






--========================================================== Fraud/Anomaly Detection Query

-- Identify accounts with frequent transfers (5 or more) for potential fraud detection
SELECT AccountID, COUNT(*) AS transfer_count, MAX(TransactionDate) AS last_transfer
FROM Transactions
WHERE TransactionType = 'Transfer'
GROUP BY AccountID
HAVING COUNT(*) >= 5
ORDER BY transfer_count DESC;