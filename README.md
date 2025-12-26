![Discovery](https://img.shields.io/badge/Discovery-No_Repeat_Customers-yellow)
![Solution](https://img.shields.io/badge/Solution-Percentile_Ranking-green)
![Scoring](https://img.shields.io/badge/Scoring-65%25_Recency%2C_35%25_Monetary-blue)
![Results](https://img.shields.io/badge/Results-53%25_High_Value-orange)
# Customer Segmentation Project
E-commerce customer value analysis with Recency + Monetary scoring model

# Project Summary

## What I Built
A customer scoring system using Recency + Monetary analysis for an e-commerce dataset.

## Key Discoveries
1. All customers had only 1 order → adapted from RFM to R+M
2. Min-max scaling failed for monetary → used percentile ranking
3. Natural score breaks at 30, 50, 60 for segmentation

## Results
- 4 segments: Champion, Loyal, Average, At Risk
- 53% of customers in top tiers (Champion + Loyal)
- Only 5% At Risk

## Skills Demonstrated
- BigQuery SQL
- Problem-solving when data contradicts assumptions
- Data visualization with Tableau

## Customer Segmentation & Value Analysis Dashboard
![Customer Segmentation Analysis](https://github.com/abdihakimhersi/customer-segmentation-project/blob/main/visualisation/Customer_Segmentation_Analysis.png?raw=true)
