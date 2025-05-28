-- Cricket SQL Case Study Submission
-- By: [Jahnvi Bhateja]
-- Database: MySQL
-- Description: This SQL script contains the table creation, data insertion, and solutions to the case study questions.
-- Assumptions:
--   1. The script should be executed sequentially.
--   2. The constraints and relationships among tables are properly maintained.


--===============================CREATING A SEPARATE DATABASE============================

CREATE DATABASE CricketDB;

--===================================CREATING TABLES======================================


-- Creating Players Table
CREATE TABLE Players (
    PlayerID INT AUTO_INCREMENT PRIMARY KEY ,
    PlayerName VARCHAR(100),
    TeamName VARCHAR(100),
    Role VARCHAR(50),
    DebutYear INT 
);

-- Creating Matches Table
CREATE TABLE Matches (
    MatchID INT AUTO_INCREMENT PRIMARY KEY ,
    MatchDate DATE,
    Location VARCHAR(100),
    Team1 VARCHAR(100),
    Team2 VARCHAR(100),
    Winner VARCHAR(100)
);

-- Creating Performance Table
CREATE TABLE Performance (
    MatchID INT,
    PlayerID INT,
    RunsScored INT,
    WicketsTaken INT,
    Catches INT,
    Stumpings INT,
    NotOut TINYINT(1),
    RunOuts INT,
    FOREIGN KEY (MatchID) REFERENCES Matches(MatchID),
    FOREIGN KEY (PlayerID) REFERENCES Players(PlayerID)
);


-- Creating Teams Table
CREATE TABLE Teams (
    TeamName VARCHAR(100) PRIMARY KEY,
    Coach VARCHAR(100),
    Captain VARCHAR(100)
);


--===========================INSERTING DATA INTO TABLES===============================



--Inserting Data into Players Table
INSERT INTO Players VALUES
(1, 'Virat Kohli', 'India', 'Batsman', 2008),
(2, 'Steve Smith', 'Australia', 'Batsman', 2010),
(3, 'Mitchell Starc', 'Australia', 'Bowler', 2010),
(4, 'MS Dhoni', 'India', 'Wicket-Keeper', 2004),
(5, 'Ben Stokes', 'England', 'All-Rounder', 2011);

--Inserting Data into Matches Table
INSERT INTO Matches VALUES
(1, '2023-03-01', 'Mumbai', 'India', 'Australia', 'India'),
(2, '2023-03-05', 'Sydney', 'Australia', 'England', 'England');

--Inserting Data into Performance Table 
INSERT INTO Performance VALUES
(1, 1, 82, 0, 1, 0, 0, 0),
(1, 4, 5, 0, 0, 1, 1, 0),
(2, 3, 15, 4, 0, 0, 0, 0);


--Inserting Data into Teams Table 
INSERT INTO Teams VALUES
('India', 'Rahul Dravid', 'Rohit Sharma'),
('Australia', 'Andrew McDonald', 'Pat Cummins');

--================================Checking the Tables===================================

SELECT * FROM Players
SELECT * FROM Matches
SELECT * FROM Performance
SELECT * FROM Teams

--======================================================================================

--==============================CRICKET CASE STUDY SOLUTIONS============================

--======================================================================================

--[[1. Identify the player with the best batting average (total runs scored divided by the 
--number of matches played) across all matches.]]

SELECT p.PlayerName,
       SUM(pe.RunsScored) * 1.0 / COUNT(DISTINCT pe.MatchID) AS AVG_Batting
FROM Players p
JOIN Performance pe ON p.PlayerID = pe.PlayerID
GROUP BY p.PlayerName
ORDER BY AVG_Batting DESC
LIMIT 1;

---------------------------------------------------------------------------------------------
--2.[[Find the team with the highest win percentage in matches played across all locations.]]

WITH MatchStats AS (
    -- Calculate matches played and won for each team
        SELECT TeamName, 
        COUNT(MatchID) AS MatchesPlayed, 
        SUM(CASE WHEN Winner = TeamName THEN 1 ELSE 0 END) AS MatchesWon
    FROM (
        -- Get all teams involved in matches
        SELECT Team1 AS TeamName, MatchID, Winner FROM Matches
        UNION ALL
        SELECT Team2 AS TeamName, MatchID, Winner FROM Matches) AS TeamsWithMatches
    GROUP BY TeamName)

SELECT TeamName, 
(MatchesWon * 100.0 / MatchesPlayed) AS WinPercentage
FROM MatchStats
ORDER BY WinPercentage DESC
LIMIT 1;--India and England are at a tie
--This is showing England as a winner due to alphabetic order.

--Alternate "ORDER BY WinPercentage DESC, MatchesPlayed DESC" in case of Tie in Win percentage.
--but here even that is in tie, so this won't work.

---------------------------------------------------------------------------------------------
--3.[[Identify the player who contributed the highest percentage of their team's total runs 
--in any single match.]]

WITH MatchRuns AS (
    -- Calculate total team runs for each match
    SELECT MatchID, TeamName, SUM(RunsScored) AS TeamTotalRuns
    FROM Performance p
    JOIN Players p1 ON p.PlayerID = p1.PlayerID
    GROUP BY MatchID, TeamName
),
PlayerContribution AS (
    -- Calculate individual player contribution percentage
    SELECT p.MatchID, p1.PlayerName, p1.TeamName, 
           p.RunsScored, 
           (p.RunsScored * 100.0) / mr.TeamTotalRuns AS ContributionPercentage
    FROM Performance p
    JOIN Players p1 ON p.PlayerID = p1.PlayerID
    JOIN MatchRuns mr ON p1.TeamName = mr.TeamName AND p.MatchID = mr.MatchID)

SELECT PlayerName, MatchID, ContributionPercentage
FROM PlayerContribution
ORDER BY ContributionPercentage DESC
LIMIT 1;

--------------------------------------------------------------------------------------------
--4.[[Determine the most consistent player, defined as the one with the smallest standard 
--deviation of runs scored across matches.]]

SELECT p.PlayerName,
STDEV(pf.RunsScored) AS RunDeviation --using standard deviation to define consistency
FROM Performance pf
JOIN Players p ON pf.PlayerID = p.PlayerID
GROUP BY p.PlayerName
ORDER BY RunDeviation ASC
LIMIT 1; --using ascending order to find the smallest deviation
 
-------------------------------------------------------------------------------------------
--5.[[Find all matches where the combined total of runs scored, wickets taken, and catches 
--exceeded 500.]]

SELECT MatchID,    
SUM(RunsScored) + SUM(WicketsTaken) + SUM(Catches) AS Total_TeamPlay 
--appending the required as Teamplay
FROM Performance
GROUP BY MatchID
HAVING SUM(RunsScored)+ SUM(WicketsTaken)+ SUM(Catches)>500

--------------------------------------------------------------------------------------------
--6.[[Identify the player who has won the most "Player of the Match" awards (highest runs 
--scored or wickets taken in a match).]]

WITH BestPerMatch AS (--ranking the players based on the criteria for "Player of the Match"
    SELECT MatchID, PlayerID, 
    RANK() OVER (PARTITION BY MatchID ORDER BY RunsScored DESC, WicketsTaken DESC) AS Rank
    FROM Performance)

SELECT
p.PlayerName, COUNT(b.MatchID) AS Awards
FROM BestPerMatch b --Using CTE to determine the player 
JOIN Players p ON b.PlayerID = p.PlayerID
WHERE b.Rank = 1
GROUP BY p.PlayerName
ORDER BY Awards DESC
LIMIT 1;--to get the one with max awards

--------------------------------------------------------------------------------------------
--7.[[Determine the team that has the most diverse player roles in their squad.]]

SELECT TeamName, COUNT(DISTINCT Role) AS UniqueRoles --using the reverse approach 
FROM Players
GROUP BY TeamName
ORDER BY UniqueRoles DESC
LIMIT 1;--least unique roles= most diverse roles

--------------------------------------------------------------------------------------------
--8.[[Identify matches where the runs scored by both teams were unequal and sort them by 
--the smallest difference in total runs between the two teams.]]

WITH TeamScores AS (--Calculating total runs scored by each team by summing up runs by each player
    SELECT MatchID, TeamName, SUM(RunsScored) AS TotalRuns
    FROM Performance p
    JOIN Players pl ON p.PlayerID = pl.PlayerID
    GROUP BY MatchID, TeamName)

SELECT t1.MatchID, ABS(t1.TotalRuns - t2.TotalRuns) AS RunDifference--finding the difference
FROM TeamScores t1
JOIN TeamScores t2 --self joining two tables 
ON t1.MatchID = t2.MatchID AND t1.TeamName <> t2.TeamName
--same match and ensures 2 different teams are being compares
WHERE t1.TotalRuns <> t2.TotalRuns--ensures different scores
ORDER BY RunDifference ASC;

--------------------------------------------------------------------------------------------
--9.[[Find players who contributed (batted, bowled, or fielded) in every match that their 
--team participated in.]]

WITH TeamMatches AS (
    -- Get the total number of matches each team participated in
    SELECT TeamName, COUNT(DISTINCT MatchID) AS TotalMatches
    FROM 
	(SELECT Team1 AS TeamName, MatchID FROM Matches
     UNION ALL
     SELECT Team2 AS TeamName, MatchID FROM Matches) AS MatchTeams
    GROUP BY TeamName),

PlayerParticipation AS (
    -- Count the number of matches each player participated in
    SELECT p.PlayerID, p.PlayerName, p.TeamName, COUNT(DISTINCT pf.MatchID) AS MatchesPlayed
    FROM Players p
    JOIN Performance pf ON p.PlayerID = pf.PlayerID
    GROUP BY p.PlayerID, p.PlayerName, p.TeamName)

-- Selecting players who played in all their team's matches
SELECT pp.PlayerName, pp.TeamName
FROM PlayerParticipation pp
JOIN TeamMatches tm ON pp.TeamName = tm.TeamName
WHERE pp.MatchesPlayed = tm.TotalMatches;

-------------------------------------------------------------------------------------------
--10.[[Identify the match with the closest margin of victory, based on runs scored by both
--teams.]]

WITH TeamScores AS (--calculating the socres for each team individually
    SELECT MatchID, TeamName, SUM(RunsScored) AS TotalRuns
    FROM Performance p
    JOIN Players pl ON p.PlayerID = pl.PlayerID
    GROUP BY MatchID, TeamName)

SELECT t1.MatchID, ABS(t1.TotalRuns - t2.TotalRuns) AS RunDifference
FROM TeamScores t1--doing a self join 
JOIN TeamScores t2 ON t1.MatchID = t2.MatchID AND t1.TeamName <> t2.TeamName
--same match and different teams
ORDER BY RunDifference ASC
LIMIT 1;--finding the smallest diff

--------------------------------------------------------------------------------------------
--11.[[Calculate the total runs scored by each team across all matches.]]

SELECT TeamName, SUM(RunsScored) AS TotalRuns
FROM Performance p
JOIN Players pl ON p.PlayerID = pl.PlayerID
GROUP BY TeamName;--groups the scores by teams

--------------------------------------------------------------------------------------------
--12.[[List matches where the total wickets taken by the winning team exceeded 2.]]

SELECT m.MatchID, m.Winner, SUM(p.WicketsTaken) AS TotalWickets
FROM Matches m
JOIN Performance p ON p.MatchID = m.MatchID 
JOIN Players pl ON p.PlayerID = pl.PlayerID 
WHERE (pl.TeamName = m.Team1 OR pl.TeamName = m.Team2)  
-- Ensure the player is part of one of the teams in the match.
  AND m.Winner = pl.TeamName  
  -- Only consider players from the winning team.
GROUP BY m.MatchID, m.Winner  -- Group by match and winning team.
HAVING SUM(p.WicketsTaken) > 2; 
-- Only include matches with winning team having than 2 wickets.

--------------------------------------------------------------------------------------------
--13. Retrieve the top 5 matches with the highest individual scores by any player.

SELECT MatchID, PlayerID, RunsScored
FROM Performance
ORDER BY RunsScored DESC
LIMIT 5;

--------------------------------------------------------------------------------------------
--14.[[Identify all bowlers who have taken at least 5 wickets across all matches.]]

SELECT p.PlayerName, SUM(pe.WicketsTaken) AS TotalWickets
FROM Performance pe
JOIN Players p ON pe.PlayerID = p.PlayerID --doing a self join
WHERE p.Role = 'Bowler'--only includes bowler 
GROUP BY p.PlayerName
HAVING SUM(pe.WicketsTaken) >= 5 ;--only filters out wickets more than 5 wickets

---------------------------------------------------------------------------------------------
--15.[[Find the total number of catches taken by players from the team that won each match.]]

SELECT m.MatchID, m.Winner, SUM(p.Catches) AS TotalCatches
FROM Matches m
JOIN Performance p ON p.MatchID = m.MatchID
JOIN Players pl ON p.PlayerID = pl.PlayerID-- Join Players to get team information for the player
WHERE pl.TeamName = m.Winner  -- Ensure we are considering only players from the winning team
GROUP BY m.MatchID, m.Winner;--groups by match and winner

---------------------------------------------------------------------------------------------
--16.[[Identify the player with the highest combined impact score in all matches.]]
--The impact score is calculated as:
--Runs scored × 1.5 + Wickets taken × 25 + Catches × 10 + Stumpings × 15 + Run outs × 10.
--Only include players who participated in at least 3 matches.

--Calculate the impact score for each player
WITH Player_Impact AS (
    SELECT 
    PlayerID, 
-- Calculate the total impact score based on the given formula
    SUM(RunsScored * 1.5 + WicketsTaken * 25 + 
        Catches * 10 + Stumpings * 15 + RunOuts * 10) AS Total_Impact,
-- Count the number of matches each player participated in
    COUNT(DISTINCT MatchID) AS MatchCount
    FROM Performance
    GROUP BY PlayerID
    -- Only consider players who have played at least 3 matches
    HAVING COUNT(DISTINCT MatchID) >= 3)

--player with the highest total impact score
SELECT P.PlayerName, 
pli.Total_Impact 
FROM Player_Impact pli
JOIN Players P ON pli.PlayerID = P.PlayerID

--player with the maximum impact score
WHERE pli.Total_Impact = (SELECT MAX(Total_Impact) FROM Player_Impact);

--------------------------------------------------------------------------------------------
--17.[[Find the match where the winning team had the narrowest margin of victory based on 
--total runs scored by both teams. If multiple matches have the same margin, list all of 
--them.]]

WITH TeamScores AS (
    -- Calculate total runs scored by each team in each match
    SELECT m.MatchID, 
           m.Team1, 
           m.Team2,
           SUM(CASE WHEN pl.TeamName = m.Team1 THEN p.RunsScored ELSE 0 END) AS Team1Runs,
           SUM(CASE WHEN pl.TeamName = m.Team2 THEN p.RunsScored ELSE 0 END) AS Team2Runs
    FROM Matches m
    JOIN Performance p ON m.MatchID = p.MatchID
    JOIN Players pl ON p.PlayerID = pl.PlayerID  -- Join with Players table to get TeamName
    GROUP BY m.MatchID, m.Team1, m.Team2
),

MatchMargins AS (
    -- Calculate the difference in runs between the winning and losing teams
SELECT MatchID, Team1,Team2,
CASE
WHEN Team1Runs > Team2Runs THEN Team1
WHEN Team2Runs > Team1Runs THEN Team2
ELSE NULL
END AS Winner,
ABS(Team1Runs - Team2Runs) AS RunDifference
FROM TeamScores)

-- Select the matches with the smallest margin
SELECT MatchID, Winner, RunDifference
FROM MatchMargins
WHERE RunDifference = (SELECT MIN(RunDifference) FROM MatchMargins);

--------------------------------------------------------------------------------------------
--18.[[List all players who have outperformed their teammates in terms of total runs scored 
--in more than half the matches they played. This requires finding matches where a player 
--scored the most runs among their teammates and calculating the percentage.]]

WITH MatchRuns AS (
    --calculates the total runs scored by each player in each match.
    SELECT MatchID, PlayerID, SUM(RunsScored) AS PlayerRuns
    FROM Performance
    GROUP BY MatchID, PlayerID),

TopScorers AS (
    -- filters out the players who scored the maximum runs in each match.
    SELECT PMR.MatchID, PMR.PlayerID
    FROM MatchRuns PMR
    WHERE PMR.PlayerRuns = (
        -- This subquery finds the maximum runs scored in each match
        SELECT MAX(PlayerRuns)
        FROM MatchRuns PMR2
        WHERE PMR.MatchID = PMR2.MatchID    )),

PlayerWinCount AS (
    -- counts how many matches each player won, i.e., how many times they scored the maximum runs in a match
    SELECT PlayerID, COUNT(*) AS WinMatches
    FROM TopScorers
    GROUP BY PlayerID),

PlayerTotalMatches AS (
    -- calculating howany distinct matches each player participated in
    SELECT PlayerID, COUNT(DISTINCT MatchID) AS TotalMatches
    FROM Performance
    GROUP BY PlayerID)

-- fetch the players who have won more than half of the matches they participated in
SELECT P.PlayerName
FROM PlayerWinCount PW
JOIN PlayerTotalMatches PT ON PW.PlayerID = PT.PlayerID
JOIN Players P ON PW.PlayerID = P.PlayerID
WHERE PW.WinMatches > PT.TotalMatches / 2;

--------------------------------------------------------------------------------------------
--19.[[Rank players by their average impact per match, considering only those who played 
--at least three matches.The impact is calculated as:
--Runs scored × 1.5 + Wickets taken × 25 + Catches × 10 + Stumpings × 15 + Run outs × 10.
--Players with the same average impact should share the same rank.]]

WITH PlayerImpact AS (
    --calculates the total impact for each player in each match
    SELECT PlayerID,MatchID,
    SUM(RunsScored) * 1.5 + SUM(WicketsTaken) * 25 + SUM(Catches) * 10 + 
    SUM(Stumpings) * 15 + SUM(RunOuts) * 10 AS TotalImpact
    FROM Performance
    GROUP BY PlayerID, MatchID),

PlayerMatchCount AS (
    --counts the total number of matches each player played
    SELECT PlayerID, COUNT(DISTINCT MatchID) AS TotalMatches
    FROM Performance
    GROUP BY PlayerID),

PlayerAverageImpact AS (
    -- calculates the average impact per match for players who played at least 3 matches
    SELECT PI.PlayerID, AVG(PI.TotalImpact) AS AvgImpact
    FROM PlayerImpact PI
    JOIN PlayerMatchCount PMC ON PI.PlayerID = PMC.PlayerID
    WHERE PMC.TotalMatches >= 3
    GROUP BY PI.PlayerID)

-- ranking players by their average impact per match
SELECT P.PlayerName, PAI.AvgImpact,
       RANK() OVER (ORDER BY PAI.AvgImpact DESC) AS Rank
FROM PlayerAverageImpact PAI
JOIN Players P ON PAI.PlayerID = P.PlayerID
ORDER BY Rank;

--------------------------------------------------------------------------------------------
--20.[[Identify the top 3 matches with the highest cumulative total runs scored by both teams.
--Rank the matches based on total runs using window functions. If multiple matches have the 
--same total runs, they should share the same rank.]]

WITH MatchTotalRuns AS ( -- Calculate total runs for each match
    SELECT MatchID, SUM(RunsScored) AS TotalMatchRuns
    FROM Performance
    GROUP BY MatchID),

RankedMatches AS ( -- Assign rank based on total runs
    SELECT MatchID, TotalMatchRuns,
           DENSE_RANK() OVER (ORDER BY TotalMatchRuns DESC) AS MatchRank
    FROM MatchTotalRuns)

-- Retrieve only the top 3 ranked matches
SELECT MatchID, TotalMatchRuns, MatchRank
FROM RankedMatches
WHERE MatchRank <= 3;

-------------------------------------------------------------------------------------------
--21.[[For each player, calculate their running cumulative impact score across all matches
--they’ve played, ordered by match date. Include only players who have played in at least 
--3 matches.]]

WITH PlayerImpact AS ( -- Calculating player's impact score per match
    SELECT P.PlayerID, P.MatchID, M.MatchDate,
           (P.RunsScored * 1.5 + P.WicketsTaken * 25 + 
            P.Catches * 10 + P.Stumpings * 15 + P.RunOuts * 10) AS ImpactScore
    FROM Performance P
    JOIN Matches M ON P.MatchID = M.MatchID), 

PlayerMatchCount AS ( -- Counting distinct matches per player
    SELECT PlayerID, COUNT(DISTINCT MatchID) AS MatchCount
    FROM Performance  
    GROUP BY PlayerID)

SELECT P.PlayerName, PI.MatchID, PI.MatchDate, -- Showing impact per match
       SUM(PI.ImpactScore) OVER (PARTITION BY PI.PlayerID ORDER BY PI.MatchDate) AS CumulativeImpact
FROM PlayerImpact PI
JOIN Players P ON PI.PlayerID = P.PlayerID
JOIN PlayerMatchCount PMC ON PI.PlayerID = PMC.PlayerID
WHERE PMC.MatchCount >= 3 -- Filtering players with at least 3 matches
ORDER BY P.PlayerName, PI.MatchDate;

--------------------------------------------------------------------------------------------
------------------------------------xxxxxxxxxxxxxxxxxxxxx-----------------------------------