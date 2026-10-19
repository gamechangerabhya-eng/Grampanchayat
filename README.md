# लासलगाव ग्रामपंचायत वेतन प्रणाली

Privacy-first Flutter Web application for preparing monthly salary workbooks for **ग्रामनिधी** and **पाणी पुरवठा**.

## Privacy model

- Employee and salary files are processed only in browser memory.
- No database, API, cloud upload, localStorage, or IndexedDB is used.
- Reloading/closing the page removes working data.
- GitHub hosts only application source and compiled static files.

## Input format

Create a CSV or XLSX file whose first sheet uses exactly these first four columns:

1. नाव
2. पद
3. वेतनश्रेणी किंवा विशेष वेतन
4. वेतन

The first row is treated as the header.

## Calculation behavior

The application automatically calculates:

- राहणीमान भत्ता: 10% of basic salary
- ग्रामपंचायत हिस्सा: 8.33% of basic salary
- Gross amount
- Total deductions
- Net payable amount
- Department totals

महागाई/सानुग्रह अनुदान and employee-specific deductions are review fields because they cannot be safely derived from the four imported fields alone. They must be entered/reviewed before final export.

## Run locally

```bash
flutter pub get
flutter run -d chrome
```

## Deploy to GitHub Pages

1. Create a GitHub repository.
2. Upload this project and push to the `main` branch.
3. In repository **Settings > Pages**, choose **GitHub Actions** as the source.
4. The included workflow analyzes, tests, builds, and deploys the web application.

## Photo notice

The hero image URL points to the Lasalgaon Gram Panchayat image published with a TV9 Marathi article. Before official/public use, replace `_photoUrl` in `lib/main.dart` with a photograph that Lasalgaon Gram Panchayat owns or is authorized to publish. This avoids dependence on an external news image and prevents hotlink failures.

## Important production note

This first source version generates a clean departmental XLSX. Exact reproduction of every merged cell, print setting, bank sheet, and PF sheet from the current official workbook should be implemented only after the payroll rules and approved blank template are finalized.
