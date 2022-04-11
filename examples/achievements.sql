-- Don't use the idents view, because it produces too many stages; instead, break it down into temporary tables
CREATE TABLE memory.default.nodes AS
    SELECT email, name, count(*) AS count
    FROM (
        SELECT author_email AS email, author_name AS name
        FROM git.default.commits
        UNION ALL
        SELECT committer_email AS email, committer_name AS name
        FROM git.default.commits
    ) names
    GROUP BY email, name;

CREATE TABLE memory.default.edges AS
    SELECT n1.name AS name1, n2.name AS name2
    FROM memory.default.nodes n1
    INNER JOIN memory.default.nodes n2 USING (email);

CREATE TABLE memory.default.idents AS
WITH RECURSIVE
    walk (name1, name2, visited) AS (
        SELECT name1, name2, ARRAY[name1]
        FROM edges
        WHERE name1 = name2
        UNION ALL
        SELECT w.name1, e.name2, w.visited || e.name2
        FROM walk w
        INNER JOIN edges e ON e.name1 = w.name2
        WHERE NOT contains(w.visited, e.name2)
    ),
    result (name1, name2s) AS (
        SELECT name1, array_agg(DISTINCT name2 ORDER BY name2)
        FROM walk
        GROUP BY name1
    ),
    grouped (names, emails) AS (
        SELECT
            array_distinct(array_agg(n.name ORDER BY n.count DESC)) AS names,
            array_distinct(array_agg(n.email ORDER BY n.count DESC)) AS emails
        FROM result r
        INNER JOIN nodes n ON n.name = r.name1
        GROUP BY r.name2s
    )
SELECT
    emails[1] AS email,
    names[1] AS name,
    slice(emails, 2, cardinality(emails)) AS extra_emails,
    slice(names, 2, cardinality(emails)) AS extra_names
FROM grouped
ORDER BY name, names;



CREATE OR REPLACE VIEW memory.default.achievements_calendar AS
SELECT * FROM (
-- id, name, description, "month", "day_from", "day_to", "doy", "dow", "minute_from", "minute_to"
VALUES
(
  'christmas'
  ,'Ruined Christmas'
  ,'Commit on Dec 25'
  ,12
  ,25
  ,25
  ,NULL
  ,NULL
  ,NULL
  ,NULL
)
,(
  'fools-day'
  ,'Fools'' Code'
  ,'Commit on Apr 1'
  ,4
  ,1
  ,1
  ,NULL
  ,NULL
  ,NULL
  ,NULL
)
,(
  'halloween'
  ,'This Code Looks Scary'
  ,'Commit on Oct 31'
  ,10
  ,31
  ,31
  ,NULL
  ,NULL
  ,NULL
  ,NULL
)
,(
  'leap-day'
  ,'Rare Occasion'
  ,'Commit on Feb 29'
  ,2
  ,29
  ,29
  ,NULL
  ,NULL
  ,NULL
  ,NULL
)
,(
  'new-year'
  ,'New Year, New Bugs'
  ,'Commit on Jan 1'
  ,1
  ,1
  ,1
  ,NULL
  ,NULL
  ,NULL
  ,NULL
)
,(
  'programmers-day'
  ,'Professional Pride'
  ,'Commit on Programmers'' Day'
  ,NULL
  ,NULL
  ,NULL
  ,256
  ,NULL
  ,NULL
  ,NULL
)
,(
  'russia-day'
  ,'From Russia with Love'
  ,'Commit on Russia Day'
  ,6
  ,12
  ,12
  ,NULL
  ,NULL
  ,NULL
  ,NULL
)
,(
  'valentine'
  ,'In Love with Work'
  ,'Commit on Feb 14'
  ,2
  ,14
  ,14
  ,NULL
  ,NULL
  ,NULL
  ,NULL
)
,(
  'thanksgiving'
  ,'Turkey Code'
  ,'Commit on Thanksgiving'
  ,10
  ,22
  ,28
  ,NULL
  ,5
  ,NULL
  ,NULL
)
,(
  'sysadmin-day'
  ,'If it works, why do we need you'
  ,'Commit on last friday in July'
  ,7
  ,-1
  ,-1
  ,NULL
  ,NULL
  ,NULL
  ,NULL
)
,(
  'time-get'
  ,'Get'
  ,'Commit exactly at 00:00'
  ,NULL
  ,NULL
  ,NULL
  ,NULL
  ,NULL
  ,0
  ,0
)
,(
  'owl'
  ,'Owl'
  ,'Commit between 4am and 7am local time'
  ,NULL
  ,NULL
  ,NULL
  ,NULL
  ,NULL
  ,4 * 60
  ,7 * 60
)
,(
  'dangerous-game'
  ,'Dangerous Game'
  ,'Commit after 6PM friday'
  ,NULL
  ,NULL
  ,NULL
  ,NULL
  ,6
  ,18 * 60
  ,NULL
)
) AS t(id, name, description, "month", "day_from", "day_to", "doy", "dow", "minute_from", "minute_to")
UNION ALL
SELECT
  'anniversary'
  ,'Anniversary'
  ,'Commit on the project''s birthday'
  ,(SELECT MONTH(commit_time) FROM commits ORDER BY commit_time ASC LIMIT 1)
  ,(SELECT DAY(commit_time) FROM commits ORDER BY commit_time ASC LIMIT 1)
  ,(SELECT DAY(commit_time) FROM commits ORDER BY commit_time ASC LIMIT 1)
  ,NULL
  ,NULL
  ,NULL
  ,NULL;


CREATE OR REPLACE VIEW memory.default.achievements_changed_lines AS
SELECT * FROM (
VALUES
(
  'world-balance'
  ,'World Balance'
  ,'Number of lines added == number of lines deleted'
  ,NULL
  ,NULL
  ,NULL
  ,NULL
  ,true
)
,(
  'massive'
  ,'Massive'
  ,'Add more than 1000 lines in a single commit'
  ,1000
  ,NULL
  ,NULL
  ,NULL
  ,NULL
)
,(
  'empty-commit'
  ,'<empty title>'
  ,'Make an empty commit'
  ,0
  ,0
  ,0
  ,0
  ,NULL
)
,(
  'eraser'
  ,'Eraser'
  ,'Make a commit with no lines added, only deletions'
  ,NULL
  ,0
  ,0
  ,NULL
  ,NULL
)
) AS t(id, name, description, added_from, added_to, removed_from, removed_to, changed_equal);


CREATE OR REPLACE VIEW memory.default.achievements_changed_files AS
SELECT * FROM (
VALUES
(
  'wrecking-ball'
  ,'Wrecking Ball'
  ,'Change more than 100 files in one commit'
  ,100
  ,CAST(NULL AS INT)
  ,CAST(NULL AS INT)
  ,CAST(NULL AS INT)
  ,NULL
  ,NULL
)
,(
  'mover'
  ,'Mover'
  ,'Move a file from one place to another without changing it'
  ,CAST(NULL AS INT)
  ,0
  ,0
  ,CAST(NULL AS INT)
  ,NULL
  ,NULL
)
,(
  'change-of-mind'
  ,'Change Of Mind'
  ,'Change license type or edit license file'
  ,CAST(NULL AS INT)
  ,CAST(NULL AS INT)
  ,CAST(NULL AS INT)
  ,CAST(NULL AS INT)
  ,ARRAY['Add', 'Modify']
  ,'(^|/)license$(?i)'
)
,(
  'gitignore'
  ,'Gitignore'
  ,'Add .gitignore'
  ,CAST(NULL AS INT)
  ,CAST(NULL AS INT)
  ,CAST(NULL AS INT)
  ,CAST(NULL AS INT)
  ,ARRAY['Add']
  ,'(^|/).gitignore$(?i)'
)
,(
  'good-boy'
  ,'Good Boy'
  ,'Create ''test'' or ''doc'' directory'
  ,CAST(NULL AS INT)
  ,CAST(NULL AS INT)
  ,CAST(NULL AS INT)
  ,CAST(NULL AS INT)
  ,ARRAY['Add']
  ,'(^|/)(test|docs|doc)/(?i)'
)
,(
  'scribbler'
  ,'Scribbler'
  ,'Create a README'
  ,CAST(NULL AS INT)
  ,CAST(NULL AS INT)
  ,CAST(NULL AS INT)
  ,CAST(NULL AS INT)
  ,ARRAY['Add']
  ,'(^|/)readme(\..+?)?$(?i)'
)
,(
  'nothing-to-hide'
  ,'Nothing to Hide'
  ,'Commit id_rsa file'
  ,CAST(NULL AS INT)
  ,CAST(NULL AS INT)
  ,CAST(NULL AS INT)
  ,CAST(NULL AS INT)
  ,ARRAY['Add']
  ,'(^|/)id_rsa$(?i)'
)
) AS t(id, name, description, changed_from, changed_to, moved_from, moved_to, change_types, path_regex);


CREATE OR REPLACE VIEW memory.default.achievements_words AS
SELECT * FROM (
VALUES
(
  'beggar'
  ,'Beggar'
  ,'Ask for an achievement in a commit message'
  ,ARRAY['achievement', 'achievements']
  ,false
  ,false
  ,NULL
  ,NULL
)
,(
  'fix'
  ,'Save The Day'
  ,'Use word “fix” in a commit message'
  ,ARRAY['fix', 'fixes', 'fixed', 'fixing']
  ,false
  ,false
  ,NULL
  ,NULL
)
,(
  'forgot'
  ,'Second Thoughts'
  ,'Use word “forgot” in a commit message'
  ,ARRAY['forgot']
  ,false
  ,false
  ,NULL
  ,NULL
)
,(
  'google'
  ,'I Can Sort It out Myself'
  ,'Use word “google” in a commit message'
  ,ARRAY['google']
  ,false
  ,false
  ,NULL
  ,NULL
)
,(
  'hack'
  ,'Real Hacker'
  ,'Use word “hack” in a commit message'
  ,ARRAY['hack']
  ,false
  ,false
  ,NULL
  ,NULL
)
,(
  'impossible'
  ,'Mission Impossible'
  ,'Use word “impossible” in a commit message'
  ,ARRAY['impossible']
  ,false
  ,false
  ,NULL
  ,NULL
)
,(
  'magic'
  ,'The Colour of Magic'
  ,'Use word “magic” in a commit message'
  ,ARRAY['magic']
  ,false
  ,false
  ,NULL
  ,NULL
)
,(
  'never-probably'
  ,'Never, Probably'
  ,'Use word “later” in a commit message'
  ,ARRAY['later']
  ,false
  ,false
  ,NULL
  ,NULL
)
,(
  'secure'
  ,'We’re Safe Now'
  ,'Use word “secure” in a commit message'
  ,ARRAY['insecure', 'secure']
  ,false
  ,false
  ,NULL
  ,NULL
)
,(
  'sorry'
  ,'Salvation'
  ,'Use word “sorry” in a commit message'
  ,ARRAY['sorry']
  ,false
  ,false
  ,NULL
  ,NULL
)
,(
  'wow'
  ,'Wow'
  ,'Use word “wow” in a commit message'
  ,ARRAY['wow']
  ,false
  ,false
  ,NULL
  ,NULL
)
,(
  'narcissist'
  ,'Narcissist'
  ,'Use your own name in a commit message'
  ,ARRAY[]
  ,true
  ,false
  ,NULL
  ,NULL
)
,(
  'bad-motherfucker'
  ,'Bad Motherf*cker'
  ,'Swear in a commit message'
  ,ARRAY['fuck', 'fucking', 'damn', 'shit']
  ,false
  ,false
  ,NULL
  ,NULL
)
,(
  'man-of-few-words'
  ,'A Man of Few Words'
  ,'Commit message with 3 letters or less'
  ,NULL
  ,false
  ,false
  ,'^([^\p{L}]*\p{L}){0,3}[^\p{L}]*$'
  ,NULL
)
,(
  'no-more-letters'
  ,'No More Letters'
  ,'Write a commit message without any letters'
  ,NULL
  ,false
  ,false
  ,'^[^\p{L}]*$'
  ,NULL
)
,(
  'emoji'
  ,'C00l kid'
  ,'Use emoji in a commit message'
  ,NULL
  ,false
  ,false
  ,'[\x{1f300}-\x{1f5ff}\x{1f600}-\x{1f64f}\x{1f680}-\x{1f6ff}\x{2600}-\x{26FF}\x{2700}-\x{2FBF}]'
  ,NULL
)
,(
  'lucky'
  ,'Lucky'
  ,'Consecutive 777 in SHA-1'
  ,NULL
  ,false
  ,false
  ,NULL
  ,'777'
)
,(
  'mark-of-the-beast'
  ,'Mark of the Beast'
  ,'Consecutive 666 in SHA-1'
  ,NULL
  ,false
  ,false
  ,NULL
  ,'666'
)
,(
  'leo-tolstoy'
  ,'Leo Tolstoy'
  ,'More than 10 lines in a commit message'
  ,NULL
  ,false
  ,false
  ,'^([^\n]*\n){10}[^\n]*$'
  ,NULL
)
) AS t(id, name, description, words, include_self, exclude_self, message_regex, id_regex)
UNION ALL
SELECT
  'blamer'
  ,'Blamer'
  ,'Use someone else’s name in a commit message'
  ,(SELECT array_agg(trim(s.name)) AS name
    FROM memory.default.idents
    CROSS JOIN UNNEST(extra_names) AS e(name)
    CROSS JOIN UNNEST(split(e.name, ' ')) AS s(name)
    WHERE trim(s.name) != '')
  ,false
  ,true
  ,NULL
  ,NULL;


CREATE OR REPLACE VIEW memory.default.achievements_languages AS
SELECT * FROM (
VALUES
(
  'basic'
  ,'Cradle of Civilization'
  ,'Add Basic file to the repo'
  ,ARRAY['bas', 'vb', 'vbs', 'vba', 'vbproj']
)
,(
  'c-sharp'
  ,'It''s Dangerous to Go Alone, Take LINQ'
  ,'Add C# file to the repo'
  ,ARRAY['cs', 'csproj']
)
,(
  'clojure'
  ,'Even Lispers Hate Lisp'
  ,'Add Clojure file to the repo'
  ,ARRAY['clj', 'cljx']
)
,(
  'clojurescript'
  ,'Even Lispers Hate Lisp (in a browser)'
  ,'Add ClojureScript file to the repo'
  ,ARRAY['cljs']
)
,(
  'css'
  ,'You Designer Now?'
  ,'Add CSS file to the repo'
  ,ARRAY['css', 'sass', 'scss', 'less', 'haml']
)
,(
  'cxx'
  ,'Troubles++14'
  ,'Add C++ file to the repo'
  ,ARRAY['c++', 'cc', 'cpp', 'cxx', 'pcc', 'hh', 'hpp', 'hxx', 'vcproj']
)
,(
  'dart'
  ,'You Work in Google?'
  ,'Add Dart file to the repo'
  ,ARRAY['dart']
)
,(
  'erlang'
  ,'It’s like ObjC, but for Ericsson phones'
  ,'Add Erlang file to the repo'
  ,ARRAY['erl', 'hrl']
)
,(
  'go'
  ,'In Google we trust'
  ,'Add Go file to the repo'
  ,ARRAY['go']
)
,(
  'haskell'
  ,'Ivory Tower'
  ,'Add Haskell file to the repo'
  ,ARRAY['hs', 'lhs']
)
,(
  'java'
  ,'Write Once. Run. Anywhere'
  ,'Add Java  file to the repo'
  ,ARRAY['java', 'jsf', 'jsp', 'jspf']
)
,(
  'javascript'
  ,'Happily Never After'
  ,'Add JavaScript file to the repo'
  ,ARRAY['js']
)
,(
  'json'
  ,'Call JSON!'
  ,'Add JSON file to the repo'
  ,ARRAY['json']
)
,(
  'objective-c'
  ,'NSVeryDescriptiveAchievementNameWithParame...'
  ,'Add Objective-C file to the repo'
  ,ARRAY['m', 'mm']
)
,(
  'pascal'
  ,'Really?'
  ,'Add Pascal file to the repo'
  ,ARRAY['pas']
)
,(
  'perl'
  ,'Chmod 200'
  ,'Add Perl file to the repo'
  ,ARRAY['pl']
)
,(
  'php'
  ,'New Facebook is Born'
  ,'Add PHP file to the repo'
  ,ARRAY['php', 'php3', 'php4', 'php5', 'phtml']
)
,(
  'python'
  ,'Snakes on a plane'
  ,'Add Python file to the repo'
  ,ARRAY['py']
)
,(
  'ruby'
  ,'Back on the Rails'
  ,'Add Ruby file to the repo'
  ,ARRAY['rake', 'rb']
)
,(
  'rust'
  ,'Can I borrow this?'
  ,'Add Rust file to the repo'
  ,ARRAY['rs', 'rlib']
)
,(
  'scala'
  ,'Well Typed, Bro'
  ,'Add Scala file to the repo'
  ,ARRAY['scala']
)
,(
  'shell'
  ,'We’ll Rewrite that Later'
  ,'Add Bash file to the repo'
  ,ARRAY['bash', 'sh', 'awk', 'sed']
)
,(
  'sql'
  ,'Not a Web Scale'
  ,'Add SQL file to the repo'
  ,ARRAY['sql']
)
,(
  'swift'
  ,'I Need to Sort Complex Objects Fast!'
  ,'Add Swift file to the repo'
  ,ARRAY['swift']
)
,(
  'windows-language'
  ,'You Can''t Program on Windows, Can You?'
  ,'Add PowerShell file to the repo'
  ,ARRAY['bat', 'btm', 'cmd', 'ps1', 'xaml']
)
,(
  'xml'
  ,'Zed’s Dead, Baby'
  ,'Add XML file to the repo'
  ,ARRAY['xml', 'xsl', 'xslt', 'xsd', 'dtd']
)
,(
  'yaml'
  ,'No means no, not Norway'
  ,'Add YAML file to the repo'
  ,ARRAY['yml', 'yaml']
)
) AS t(id, name, description, extensions);


/*+
 *

 {:description "StackOverflow URL in a commit body or message",
  :key :citation-needed,
  :name "Citation Needed"}

 {:description "5+ swear words in a commit message",
  :key :hello-linus,
  :name "Hello, Linus",
  :level-description "One level for each 5 swear words in a message"}

 {:description "Make commit #1000, or #1111, or #1234",
  :key :get,
  :name "Get"}



 {:description "Add GPL license file to the repo",
  :key :for-stallman,
  :name "For Stallman!"}

 {:description "Commit 2Mb file or bigger",
  :key :fat-ass,
  :name "Fat Ass"}

 {:description "Commit a file with just trailing spaces removed",
  :key :ocd,
  :name "OCD"}

 {:description "Delete a file that has been added in the initial commit (and at least a year has passed)",
  :key :all-things-die,
  :name "All Things Die"}

 {:description "Commit time is 1 month or more after the author time",
  :key :alzheimers,
  :name "Alzheimer's"}

 {:description "Misspell a word in a commit message",
  :key :borat,
  :name "Borat",
  :level-description "One level for each misspelled word in a message"}

 {:description "Make 10+ commits with the same message",
  :key :catchphrase,
  :name "Catchphrase"}

 {:description
  "Publish commit with the same N first chars of SHA-1 as existing commit",
  :key :collision,
  :name "Collision"}

 {:description "10+ commits in a row",
  :key :combo,
  :name "Combo"}

 {:description "Make a commit after someone had 10+ commits in a row",
  :key :combo-breaker,
  :name "Combo Breaker"}

 {:description "Only add a comment",
  :key :commenter,
  :name "Commenter"}

 {:description "Swap two lines",
  :key :easy-fix,
  :name "Easy Fix"}

 {:description "Change tabs to spaces or vice versa",
  :key :holy-war,
  :name "Holy War"}

 {:description "Update master branch with force mode",
  :key :deal-with-it,
  :name "Deal with it"}

 {:description "Make a commit with 3+ parents",
  :key :hydra,
  :name "Hydra"}

 {:description
  "Add/edit files in 3+ different languages in a single commit",
  :key :multilingual,
  :name "Multilingual"}

 {:description "Two different commits within 15 seconds",
  :key :flash,
  :name "Flash"}

 {:description "You are the only committer for a month",
  :key :loneliness,
  :name "Loneliness"}

 {:description "Make a commit to a repo that hasn’t been touched for 1 month or more",
  :key :necromancer,
  :name "Necromancer"}

 {:description "Make 100+ non-merge commits",
  :key :worker-bee,
  :name "Worker Bee"}

 {:description "Commit and revert commit within 1 minute",
  :key :ooops,
  :name "Ooops"}

 {:description "Your commit was reverted completely by someone else",
  :key :waste,
  :name "Waste"}

 {:description "Edit a file that hasn’t been touched for a year",
  :key :what-happened-here,
  :name "What Happened Here?"}

 {:description "Resolve 100 conflicts",
  :key :peacemaker,
  :name "Peacemaker"}



 {:description "Get 5 achievements with 1 commit",
  :key :munchkin,
  :name "Munchkin"}

 {:description "Get all achievements",
  :key :quest-complete,
  :name "Quest Complete"}

 {:description "Zero achievments after 100 your own commits",
  :key :unpretending,
  :name "Unpretending"}
])
*/


CREATE TABLE memory.default.acquired_calendar AS select
    a.id,
    a.name,
    a.description,
    i.name AS author_name,
    i.email,
    min_by(c.object_id, c.commit_time) AS achieved_in,
    min(c.commit_time) AS achieved_at,
    count(*) AS num_achieved
FROM commits c
JOIN memory.default.idents i ON c.author_email = i.email OR CONTAINS(i.extra_emails, c.author_email)
JOIN memory.default.achievements_calendar a ON
  (a.month IS NULL OR MONTH(c.commit_time) = a.month)
  AND DAY(c.commit_time) BETWEEN COALESCE(a.day_from, 1) AND COALESCE(a.day_to, 31)
  AND (a.doy IS NULL OR DOY(c.commit_time) = a.doy)
  AND (a.dow IS NULL OR DOW(c.commit_time) = a.dow)
  AND (EXTRACT(HOUR FROM c.commit_time) * 60 + EXTRACT(MINUTE FROM c.commit_time)) BETWEEN COALESCE(a.minute_from, 0) AND COALESCE(a.minute_to, 60 * 24)
GROUP BY
    a.id,
    a.name,
    a.description,
    i.name,
    i.email;

CREATE TABLE memory.default.acquired_changed_files AS SELECT
    a.id,
    a.name,
    a.description,
    i.name AS author_name,
    i.email,
    min_by(c.object_id, c.commit_time) AS achieved_in,
    min(c.commit_time) AS achieved_at,
    count(*) AS num_achieved
FROM commits c
JOIN (
  SELECT
    commit_id,
    change_type,
    path_name,
    count(*) FILTER (WHERE change_type = 'Rename' AND added_lines = 0 AND deleted_lines = 0) AS renamed,
    count(*) FILTER (WHERE change_type != 'Rename' OR (added_lines != 0 AND deleted_lines != 0)) AS modified
  FROM diff_stats
  GROUP BY commit_id, change_type, path_name
) s ON s.commit_id = c.object_id
JOIN memory.default.idents i ON c.author_email = i.email OR CONTAINS(i.extra_emails, c.author_email)
JOIN memory.default.achievements_changed_files a ON
  s.renamed BETWEEN COALESCE(a.moved_from, 0) AND COALESCE(a.moved_to, bitwise_right_shift(bitwise_not(0), 1))
  AND s.modified BETWEEN COALESCE(a.changed_from, 0) AND COALESCE(a.changed_to, bitwise_right_shift(bitwise_not(0), 1))
  AND (a.change_types IS NULL OR contains(a.change_types, s.change_type))
  AND (a.path_regex IS NULL OR regexp_like(s.path_name, a.path_regex))
GROUP BY
    a.id,
    a.name,
    a.description,
    i.name,
    i.email;


CREATE TABLE memory.default.acquired_changed_lines AS SELECT
    a.id,
    a.name,
    a.description,
    i.name AS author_name,
    i.email,
    min_by(c.object_id, c.commit_time) AS achieved_in,
    min(c.commit_time) AS achieved_at,
    count(*) AS num_achieved
FROM commit_stats c
JOIN memory.default.idents i ON c.author_email = i.email OR CONTAINS(i.extra_emails, c.author_email)
JOIN memory.default.achievements_changed_lines a ON
  c.added_lines BETWEEN COALESCE(a.added_from, 0) AND COALESCE(a.added_to, bitwise_right_shift(bitwise_not(0), 1))
  AND c.deleted_lines BETWEEN COALESCE(a.removed_from, 0) AND COALESCE(a.removed_from, bitwise_right_shift(bitwise_not(0), 1))
  AND (NOT changed_equal OR c.added_lines = c.deleted_lines)
GROUP BY
    a.id,
    a.name,
    a.description,
    i.name,
    i.email;


CREATE TABLE memory.default.acquired_languages AS SELECT
    a.id,
    a.name,
    a.description,
    i.name AS author_name,
    i.email,
    min_by(c.object_id, c.commit_time) AS achieved_in,
    min(c.commit_time) AS achieved_at,
    count(DISTINCT c.object_id) AS num_achieved
FROM (
  SELECT
    c.commit_time,
    c.object_id,
    c.author_email,
    array_agg(DISTINCT reverse(split_part(reverse(s.path_name), '.', 1))) AS extensions
  FROM commits c
  JOIN diff_stats s ON s.commit_id = c.object_id AND s.change_type = 'Add'
  GROUP BY c.commit_time, c.object_id, c.author_email
  UNION
  SELECT
    c.commit_time,
    c.object_id,
    c.author_email,
    array_agg(DISTINCT reverse(split_part(reverse(t.file_name), '.', 1))) AS extensions
  FROM commits c
  JOIN trees t ON t.commit_id = c.object_id
  WHERE CARDINALITY(c.parents) = 0
  GROUP BY c.commit_time, c.object_id, c.author_email
) c
JOIN memory.default.idents i ON c.author_email = i.email OR CONTAINS(i.extra_emails, c.author_email)
JOIN memory.default.achievements_languages a ON
  arrays_overlap(c.extensions, a.extensions)
GROUP BY
    a.id,
    a.name,
    a.description,
    i.name,
    i.email;


CREATE TABLE memory.default.acquired_words AS SELECT
    a.id,
    a.name,
    a.description,
    i.name AS author_name,
    i.email,
    min_by(c.object_id, c.commit_time) AS achieved_in,
    min(c.commit_time) AS achieved_at,
    count(*) AS num_achieved
FROM (
  SELECT
    commit_time,
    object_id,
    author_email,
    message,
    TRANSFORM(FILTER(regexp_split(message, '[^\p{Alphabetic}\p{Digit}]'), x -> x != ''), x -> lower(x)) AS words
  FROM commits
) c
JOIN (
  SELECT
    name,
    email,
    extra_emails,
    TRANSFORM(FILTER(regexp_split(name || ' ' || concat_ws(' ', extra_names), '[^\p{Alphabetic}\p{Digit}]'), x -> x != ''), x -> lower(x)) AS words
  FROM memory.default.idents
) i ON c.author_email = i.email OR CONTAINS(i.extra_emails, c.author_email)
JOIN memory.default.achievements_words a ON
  (a.words IS NULL OR arrays_overlap(a.words, c.words))
  AND (NOT include_self OR arrays_overlap(c.words, i.words))
  AND (NOT exclude_self OR NOT arrays_overlap(c.words, i.words))
  AND (a.message_regex IS NULL OR regexp_like(c.message, a.message_regex))
  AND (a.id_regex IS NULL OR regexp_like(c.object_id, a.id_regex))
GROUP BY
    a.id,
    a.name,
    a.description,
    i.name,
    i.email;

-- List all achievements with num of all wins, percentage of winners, date and commit id of first win and top3 winners (by number of wins, first winner wins ties)
WITH acha AS (
  SELECT id, name, description FROM memory.default.achievements_calendar
  UNION ALL
  SELECT id, name, description FROM memory.default.achievements_changed_files
  UNION ALL
  SELECT id, name, description FROM memory.default.achievements_changed_lines
  UNION ALL
  SELECT id, name, description FROM memory.default.achievements_languages
  UNION ALL
  SELECT id, name, description FROM memory.default.achievements_words
), acq AS (
  SELECT * FROM memory.default.acquired_calendar
  UNION ALL
  SELECT * FROM memory.default.acquired_changed_files
  UNION ALL
  SELECT * FROM memory.default.acquired_changed_lines
  UNION ALL
  SELECT * FROM memory.default.acquired_languages
  UNION ALL
  SELECT * FROM memory.default.acquired_words
)
SELECT
  acha.name,
  acha.description,
  count(acq.id) AS num_winners,
  FORMAT('%.2f', 100 * cast(count(acq.id) AS DOUBLE) / i.idents_count) AS percent_winners,
  min(acq.achieved_at) AS first_achieved_at,
  min_by(acq.achieved_in, acq.achieved_at) AS first_achieved_in,
  slice(array_agg(acq.author_name || ' <' || acq.email || '>' ORDER BY acq.num_achieved DESC, acq.achieved_at), 1, 3) AS top3
FROM acha
LEFT JOIN acq ON acq.id = acha.id
CROSS JOIN (SELECT COUNT(*) AS idents_count FROM memory.default.idents) i
GROUP BY acha.id, acha.name, acha.description, i.idents_count
ORDER BY NULLIF(num_winners, 0) NULLS LAST, acha.name
;

-- List all winners with num and percent of achievements and all achievements (with date and commit)
WITH acha AS (
  SELECT id, name, description FROM memory.default.achievements_calendar
  UNION ALL
  SELECT id, name, description FROM memory.default.achievements_changed_files
  UNION ALL
  SELECT id, name, description FROM memory.default.achievements_changed_lines
  UNION ALL
  SELECT id, name, description FROM memory.default.achievements_languages
  UNION ALL
  SELECT id, name, description FROM memory.default.achievements_words
), acq AS (
  SELECT * FROM memory.default.acquired_calendar
  UNION ALL
  SELECT * FROM memory.default.acquired_changed_files
  UNION ALL
  SELECT * FROM memory.default.acquired_changed_lines
  UNION ALL
  SELECT * FROM memory.default.acquired_languages
  UNION ALL
  SELECT * FROM memory.default.acquired_words
)
SELECT
  acq.author_name,
  acq.email,
  count(acq.id) OVER w AS num_achievements,
  format('%.2f', 100 * cast(count(acq.id) OVER w AS double) / a.achievements_count) AS percent_achievments,
  acq.name,
  acq.description,
  acq.achieved_in,
  acq.achieved_at,
  acq.num_achieved
FROM acha
LEFT JOIN acq ON acq.id = acha.id
CROSS JOIN (SELECT COUNT(*) AS achievements_count FROM acha) a
WINDOW w (PARTITION BY acq.email)
ORDER BY acq.author_name, acq.name
;
