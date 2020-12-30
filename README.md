# Colorchain Jekyll Web-Site

If you host your site on your own, script to scrap data is in _data folder.
CSV files there contain data, and all data are auto-shown on main and history pages.
You can run server with 'bundle exec jekyl serve' to test localy.

If you plan to host it on GitHub, scrapper for data can work in 2 ways:

1. Hosting on heroku, to scrap data each day and update git repository _data folder with CSV files
2. Hosting localy, executing as cron job to scrap data and update git repository.

