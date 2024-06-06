/*
movies(movid, title, country, duration, releasedate, description)
users(userid, uname, email, dateofbirth)
releaselanguages(movid, language) movid references movies
moviegenres(movid, genre) movid references movies
review(userid, movid, reviewdate, rating, reviewtxt)userid references users,movid references movies
*/

/*
11. List the title, release date and language(s) of all the movies that were released in French or Italian
    (it may also have releases in other languages but should have been released in at least one of these languages).
    The output should be ordered by release date and then by title. If a movie is released in both French and
    Italian then it should be listed only once in the output as a single output in the form French,Italian
    ( in that alphabetical order of languages and comma separated, but no spaces between the
    values). DO NOT output it as Italian,French Do not include other languages in the output listing (only the
    above two). Name this ouput column languages.
    sameple output:
    title | releasedate | languages
    ------------------------------------
    Movie1 | 1946-01-16 | French,Italian
    Movie3 | 1967-02-23 | Italian
    Movie2 | 1975-05-10 | French
    Movie4 | 2011-03-13 | French,Italian
*/
SELECT title, releasedate,
       CASE
           WHEN COUNT(DISTINCT CASE WHEN rl.language = 'French' THEN 'French' END) > 0
                AND COUNT(DISTINCT CASE WHEN rl.language = 'Italian' THEN 'Italian' END) > 0 THEN 'French,Italian'
           WHEN COUNT(DISTINCT CASE WHEN rl.language = 'French' THEN 'French' END) > 0 THEN 'French'
           WHEN COUNT(DISTINCT CASE WHEN rl.language = 'Italian' THEN 'Italian' END) > 0 THEN 'Italian'
       END AS languages
FROM movies m
JOIN releaselanguages rl ON m.movid = rl.movid
WHERE rl.language IN ('French', 'Italian')
GROUP BY m.movid, m.title, m.releasedate
ORDER BY m.releasedate, m.title;

/*
12. List the user IDs and names of users who have not reviewed any movie in the 'Horror' genre.
*/
SELECT u.userid, u.uname
FROM users u
WHERE NOT EXISTS (
    SELECT 1
    FROM review r
    JOIN moviegenres mg ON r.movid = mg.movid
    WHERE r.userid = u.userid AND mg.genre = 'Horror'
);
--left join 
SELECT u.userid, u.uname
FROM users u
LEFT JOIN (
    SELECT DISTINCT r.userid
    FROM review r
    JOIN moviegenres mg ON r.movid = mg.movid
    WHERE mg.genre = 'Horror'
) horror_reviews ON u.userid = horror_reviews.userid
WHERE horror_reviews.userid IS NULL;

/*
13. List the name and email address of all the users who have written a review for a movie that was
    released ONLY in French (they are free to write reviews for any other movies). Order the output by the
    email.
*/
SELECT DISTINCT u.uname, u.email
FROM users u
JOIN review r ON u.userid = r.userid
JOIN movies m ON r.movid = m.movid
WHERE m.movid IN (
    SELECT movid
    FROM releaselanguages
    WHERE language = 'French'
    GROUP BY movid
    HAVING COUNT(DISTINCT language) = 1
)
ORDER BY u.email;

/*
14. Find the number of Comedy movies that was released in the year 2024. 
    Name the output column nummovies.
*/
SELECT COUNT(DISTINCT m.movid) AS nummovies
FROM movies m
JOIN moviegenres mg ON m.movid = mg.movid
WHERE mg.genre = 'Comedy' AND EXTRACT(YEAR FROM m.releasedate) = 2024;

/*
15. List the title and release date of all the movies that were released in both 
    (and not just either) English and French and also had 5 or more reviews. 
    Order the output by release date and then by title. 
    Whether the movies had been released in other languages are irrelevant.
*/
SELECT m.title, m.releasedate
FROM movies m
JOIN releaselanguages rl1 ON m.movid = rl1.movid
JOIN releaselanguages rl2 ON m.movid = rl2.movid
JOIN review r ON m.movid = r.movid
WHERE rl1.language = 'English' AND rl2.language = 'French'
GROUP BY m.movid, m.title, m.releasedate
HAVING COUNT(r.reviewid) >= 5
ORDER BY m.releasedate, m.title;

/*
16. List the movid and titles of movies that have had an increasing average rating
    over three consecutive years in ascending order.
*/
WITH yearly_ratings AS (
    SELECT m.movid, m.title, EXTRACT(YEAR FROM r.reviewdate) AS year, AVG(r.rating) AS avg_rating
    FROM movies m
    JOIN review r ON m.movid = r.movid
    GROUP BY m.movid, m.title, EXTRACT(YEAR FROM r.reviewdate)
),
avg_rating_changes AS (
    SELECT yr1.movid, yr1.title
    FROM yearly_ratings yr1
    JOIN yearly_ratings yr2 ON yr1.movid = yr2.movid AND yr2.year = yr1.year + 1
    JOIN yearly_ratings yr3 ON yr1.movid = yr3.movid AND yr3.year = yr2.year + 1
    WHERE yr1.avg_rating < yr2.avg_rating AND yr2.avg_rating < yr3.avg_rating
)
SELECT DISTINCT title
FROM avg_rating_changes
ORDER BY title;

/*
17. List the title and release date of all movies with less than 2 reviews 
    (make sure to take into account the movies with zero reviews). 
    Order the output by release date and then by title.
*/
SELECT m.title,m.releasedate
FROM movies m LEFT JOIN review r ON m.movid=r.movid
GROUP BY m.movid,m.title,m.releasedate
HAVING COUNT(DISTINCT r.reviewid)<2
ORDER BY m.releasedate,m.title;

/*
18. List the title, release date and number of reviews of all movies released in 2024. 
    If a movie has no reviews, it should be shown as 0. 
    Name the column with the number of reviews as numreviews. 
    Order the output such that the movies with most reviews are on the top. 
    For movies with same number of reviews, order by their release dates and then by titles.
*/
SELECT m.title, m.releasedate, COUNT(r.reviewid) AS numreviews
FROM movies m LEFT JOIN review r ON m.movid = r.movid
WHERE EXTRACT(YEAR FROM m.releasedate) = 2024
GROUP BY m.movid, m.title, m.releasedate
ORDER BY numreviews DESC, m.releasedate, m.title;

/*
19. List the title and release date of all movies with the maximum number (count) of reviews. 
    Order the output by release date and then by title.
*/
WITH babytable(title, releasedate, s) AS (
    SELECT title, releasedate, COUNT(*) AS s
    FROM movies
    LEFT JOIN review r ON movies.movid = r.movid
    GROUP BY title, releasedate
)
SELECT title, releasedate
FROM babytable
WHERE s = (SELECT MAX(s) FROM babytable)
ORDER BY releasedate, title;

/*
20. List the title, release date and average rating of all movies with at the least two reviews. 
    Name the average rating column avgrating. 
    Order the output such that the movies with the highest average ratings are at the top.
    If two movies have the same average rating, then order them further by their release dates and then by titles.
*/
SELECT m.title, m.releasedate, AVG(r.rating) AS avgrating
FROM movies m
JOIN review r ON m.movid = r.movid
GROUP BY m.movid, m.title, m.releasedate
HAVING COUNT(r.reviewid) >= 2
ORDER BY avgrating DESC, m.releasedate, m.title;

/*
21. List the title of the movie and the number of reviews for the latest (release date) movie 
    (There could possibly be more than one movie that qualifies).
    Movies with no reviews yet should not be ignored in the output. 
    Name the number of reviews as numreviews. Order the output based on the title of the movie.
*/
WITH cte1 AS (--find the last movie 
    SELECT title, releasedate
    FROM movies
    WHERE releasedate = (
        SELECT MAX(releasedate)
        FROM movies
    )
)
SELECT lm.title, COUNT(r.reviewid) AS numreviews
FROM cte1 lm LEFT JOIN review r ON lm.title = r.title
GROUP BY lm.title
ORDER BY lm.title;
--method2
WITH baby1(title, releasedate, numreviews) AS (
    SELECT title, releasedate,
           CASE WHEN s = 0 THEN 0
                ELSE COUNT(s)
           END AS numreviews
    FROM (
        SELECT m.title, m.releasedate, COALESCE(r.movid, 0) AS s
        FROM movies m
        LEFT JOIN review r ON m.movid = r.movid
    ) foo
    GROUP BY title, releasedate, s
)
SELECT title, numreviews
FROM baby1
WHERE releasedate = (SELECT MAX(releasedate) FROM baby1)
ORDER BY title;

/*
22. This query is a simple attempt of a recommendation system.
    List the title and release date of movies,their average ratings for Comedy movies not reviewed by cinebuff@movieinfo.com (email) 
    such that the average rating of each movie is the same or higher than the average rating given by cinebuff@movieinfo.com across all Comedy movies. 
    Name the average rating column avgrating. Order the output such that the movies with a higher average rating is at the top. 
    For movies with same average rating, order them by the release date and then by the title. 
    We can assume that there will be some Comedy movies reviewed by this user in the database.
*/

--Caculate average comedy rating 
--Caculate average comedy rating given by cine
--title,releasedate,avg rating of comedy not rate by cine 
WITH comedy_movies AS (
    SELECT m.movid, m.title, m.releasedate, AVG(r.rating) AS avgrating
    FROM movies m
    JOIN moviegenres mg ON m.movid = mg.movid
    LEFT JOIN review r ON m.movid = r.movid
    WHERE mg.genre = 'Comedy'
    GROUP BY m.movid, m.title, m.releasedate
),
cinebuff_avg_rating AS (
    SELECT AVG(r.rating) AS avg_cinebuff_rating
    FROM review r
    JOIN movies m ON r.movid = m.movid
    JOIN users u ON r.userid = u.userid
    JOIN moviegenres mg ON m.movid = mg.movid
    WHERE u.email = 'cinebuff@movieinfo.com'
    AND mg.genre = 'Comedy'
)
SELECT cm.title, cm.releasedate, cm.avgrating
FROM comedy_movies cm
JOIN cinebuff_avg_rating car ON cm.avgrating >= car.avg_cinebuff_rating
WHERE cm.movid NOT IN (
    SELECT r.movid
    FROM review r JOIN users u ON r.userid = u.userid
    WHERE u.email = 'cinebuff@movieinfo.com'
)
ORDER BY cm.avgrating DESC, cm.releasedate, cm.title;

/*
23. Find the genre that is most liked by cinebuff@movieinfo.com (email). 
    start by computing the average rating this user has given to movies of different genres. 
    Keep in mind that a movie may fall into multiple genres and therefore its rating would contribute to all of those genres. You may also
    end up with a situation where more than one genre might have the same highest average rating. 
    In such cases,order the output by the genre. 
    We can assume that this user has made some movie reviews.
*/
WITH cine_genre_ratings AS (
    SELECT mg.genre, AVG(r.rating) AS avg_rating
    FROM review r
    JOIN users u ON r.userid = u.userid
    JOIN movies m ON r.movid = m.movid
    JOIN moviegenres mg ON m.movid = mg.movid
    WHERE u.email = 'cinebuff@movieinfo.com'
    GROUP BY mg.genre
)
SELECT genre, avg_rating
FROM cine_genre_ratings
WHERE avg_rating = (
    SELECT MAX(avg_rating)
    FROM cine_genre_ratings
)
ORDER BY genre;

/*
24. Find the movies that fell out of popularity. 
    List the title and release date of all the movies that had an average rating of 7 or above before 2019 
    but has an average rating of 5 or lower starting 2023 
    take into account movies with no reviews in the later period as 0 rating. 
    Order the output by their release date and then by title.
*/
WITH before_2023 AS (
    SELECT m.movid, m.title, m.releasedate, AVG(r.rating) AS avgrating
    FROM movies m
    LEFT JOIN review r ON m.movid = r.movid
    WHERE r.reviewdate < '2023-01-01'
    GROUP BY m.movid, m.title, m.releasedate
),
after_2023 AS (
    SELECT m.movid, AVG(COALESCE(r.rating, 0)) AS avgrating
    FROM movies m
    LEFT JOIN review r ON m.movid = r.movid
    WHERE r.reviewdate >= '2023-01-01' OR r.reviewid IS NULL
    GROUP BY m.movid
)
SELECT bf.title, bf.releasedate
FROM before_2023 bf
JOIN after_2023 af ON bf.movid = af.movid
WHERE bf.avgrating >= 7 AND af.avgrating <= 5
ORDER BY bf.releasedate, bf.title;

/*
25. List all the languages in the database and the genre that has most movies for that language. 
    If two genres are equally the most popular for the language, produce two rows in the output (and so forth). 
    Order the output by languages and then by genre.
*/
--count of movies for each genre and each language
--max movies count for each language
--highest movie count for each language

WITH language_genre_counts AS (
    SELECT rl.language, mg.genre, COUNT(*) AS movie_count
    FROM releaselanguages rl JOIN moviegenres mg ON rl.movid = mg.movid
    GROUP BY rl.language, mg.genre
),
max_genre_counts AS (
    SELECT language, MAX(movie_count) AS max_count
    FROM language_genre_counts
    GROUP BY language
)
SELECT lgc.language, lgc.genre
FROM language_genre_counts lgc JOIN max_genre_counts mgc ON lgc.language = mgc.language AND lgc.movie_count = mgc.max_count
ORDER BY lgc.language, lgc.genre;