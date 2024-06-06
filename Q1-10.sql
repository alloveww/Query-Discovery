/*
movies(movid, title, country, duration, releasedate, description)
users(userid, uname, email, dateofbirth)
releaselanguages(movid, language) movid references movies
moviegenres(movid, genre) movid references movies
review(userid, movid, reviewdate, rating, reviewtxt)userid references users,movid references movies
*/

/*
1.  List the movie id and title of all movies released on or after the year 2021. The output should be
    ordered by the movie id.
*/
SELECT DISTINCT movid, title
FROM movies
WHERE releasedate >= '2021-01-01'
ORDER BY movid;

/*
2.  Find the user id of all the users who have reviewed the movie (title) Casablanca. 
    The output should be ordered by the user id. 
    May assume that there is only one movie with this title.
*/
SELECT DISTINCT r.userid
FROM review r
JOIN movies m ON r.movid = m.movid
WHERE m.title = 'Casablanca'
ORDER BY r.userid;

/*
3.  List the user id of all the users who gave a favourable review (rating 7 and above) for the 1959 version
    of the movie (title) Ben-Hur but did not review or gave an unfavourable review (rating 4 and below) for the
    2016 version of the movie. The output should be ordered by the user id.
*/
WITH favourable_reviews AS (
    SELECT r.userid
    FROM review r
    JOIN movies m ON r.movid = m.movid
    WHERE m.title = 'Ben-Hur' AND m.releasedate LIKE '1959%' AND r.rating >= 7
),
unfavourable_reviews AS (
    SELECT r.userid
    FROM review r
    JOIN movies m ON r.movid = m.movid
    WHERE m.title = 'Ben-Hur' AND m.releasedate LIKE '2016%' AND (r.rating <= 4 OR r.rating IS NULL)
)
SELECT DISTINCT fr.userid
FROM favourable_reviews fr
JOIN unfavourable_reviews ur ON fr.userid = ur.userid
WHERE ur.userid IS NULL
ORDER BY fr.userid;

/*
4.  sort movies according to their duration in descending order
*/
SELECT title, releasedate, duration
FROM movies
ORDER BY duration DESC;

/*
5.  List all the movies (title), release date and the ratings for the reviews done by the user 
    whose email is talkiesdude@movieinfo.com. 
    The output should be ordered with the highest ratings on top. If two movies have the same ratings,
    then they should be ordered by their release dates and then by titles.
*/
SELECT DISTINCT title, releasedate, rating
FROM movies,review
WHERE
      review.movid=movies.movid AND
      userid = (SELECT DISTINCT userid FROM users WHERE email='talkiesdude@movieinfo.com')
ORDER BY rating DESC , releasedate ASC , title ASC ;

/*
6.  Find pairs of movies released in the same month and year. 
    List the titles and release dates of such pairs.
*/
SELECT m1.title AS title1, m1.releasedate AS date1, m2.title AS title2, m2.releasedate AS date2
FROM movies m1
JOIN movies m2 ON EXTRACT(YEAR FROM m1.releasedate) = EXTRACT(YEAR FROM m2.releasedate)
                AND EXTRACT(MONTH FROM m1.releasedate) = EXTRACT(MONTH FROM m2.releasedate)
                AND m1.movid < m2.movid
ORDER BY date1, title1, title2;

/*
7.  Give the list of movies (titles) and release dates of movies released in the year 2021 
    that falls into both the genres Comedy and Sci-Fi 
    (i.e., a movie should be part of both the genres and not just one). 
    Order the ouput by release date and then by titles.
*/
SELECT title,releasedate
FROM movies
WHERE extract (year from releasedate) = '2021'
AND movid IN (
    SELECT distinct movid FROM moviegenres WHERE (genre='Comedy') 
    INTERSECT
    SELECT distinct movid FROM moviegenres WHERE (genre='Sci-Fi')
    )
ORDER BY releasedate, title;

/*
8.  Find top 3 movies with the highest average rating for each Genre.
    List the genre,movie title, and average rating in descending order.
*/
WITH cte AS(
    SELECT genre,title,AVG(rating) AS avg_rating,
            ROW_NUMBER()OVER(PARTITION BY genre ORDER BY AVG(r.rating) DESC)
    FROM movies m
    JOIN review r ON m.movid = r.movid
    JOIN moviegenres mg ON m.movid = mg.movid
    GROUP BY mg.genre, m.title
)
SELECT genre,title,avg_rating
FROM cte
WHERE rank<=3
ORDER BY genre,avg_rating DESC;

/*
9.  List the title and release date of movies that were produced in French but not in English.
    The output should be ordered by the release date and then by the title.
*/
SELECT title,releasedate
FROM movies
WHERE movid IN
    (SELECT DISTINCT movid FROM releaselanguages WHERE language='French' 
    EXCEPT
    SELECT DISTINCT movid FROM releaselanguages WHERE language='English')
ORDER BY releasedate, title;

/*
10. Identify users who have consistently rated all their reviewed movies with the same rating. 
    List the user ID and name.
*/
SELECT u.userid, u.uname
FROM users u
JOIN review r ON u.userid = r.userid
GROUP BY u.userid, u.uname
HAVING MIN(r.rating) = MAX(r.rating);

