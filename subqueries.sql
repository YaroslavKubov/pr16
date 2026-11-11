
-- Практична робота №16
-- Складання запитів із підзапитами
-- База даних: college

BEGIN;

-- =====================================================
-- 1. ПІДГОТОВКА ТЕСТОВИХ ДАНИХ
-- =====================================================

-- Створення таблиці студентів, якщо її ще немає
CREATE TABLE IF NOT EXISTS college.students (
    student_id INTEGER PRIMARY KEY,
    student_name VARCHAR(100) NOT NULL,
    email VARCHAR(120) UNIQUE
);

-- Додавання тестових підрозділів
INSERT INTO college.departments (code, name)
VALUES
    ('S16PH', 'Фізика (ПР16)'),
    ('S16IT', 'Інформаційні технології (ПР16)')
ON CONFLICT (code) DO NOTHING;

-- Додавання курсів підрозділу фізики
INSERT INTO college.courses
    (department_id, course_name, credits, tuition_fee)
SELECT d.department_id, 'ПР16 Фізика 5 кредитів', 5, 1500
FROM college.departments d
WHERE d.code = 'S16PH'
AND NOT EXISTS (
    SELECT 1 FROM college.courses
    WHERE course_name = 'ПР16 Фізика 5 кредитів'
);

INSERT INTO college.courses
    (department_id, course_name, credits, tuition_fee)
SELECT d.department_id, 'ПР16 Фізика 7 кредитів', 7, 2000
FROM college.departments d
WHERE d.code = 'S16PH'
AND NOT EXISTS (
    SELECT 1 FROM college.courses
    WHERE course_name = 'ПР16 Фізика 7 кредитів'
);

-- Додавання курсів іншого підрозділу
INSERT INTO college.courses
    (department_id, course_name, credits, tuition_fee)
SELECT d.department_id, 'ПР16 Програмування 6 кредитів', 6, 1800
FROM college.departments d
WHERE d.code = 'S16IT'
AND NOT EXISTS (
    SELECT 1 FROM college.courses
    WHERE course_name = 'ПР16 Програмування 6 кредитів'
);

INSERT INTO college.courses
    (department_id, course_name, credits, tuition_fee)
SELECT d.department_id, 'ПР16 Програмування 8 кредитів', 8, 2500
FROM college.departments d
WHERE d.code = 'S16IT'
AND NOT EXISTS (
    SELECT 1 FROM college.courses
    WHERE course_name = 'ПР16 Програмування 8 кредитів'
);

-- Додавання тестових студентів
INSERT INTO college.students (student_id, student_name, email)
VALUES
    (991601, 'Студент ПР16 №1', 'student16_1@example.com'),
    (991602, 'Студент ПР16 №2', 'student16_2@example.com')
ON CONFLICT (student_id) DO NOTHING;

-- Реєстрація студентів на тестові курси
INSERT INTO college.enrollments (student_id, course_id)
SELECT 991601, c.course_id
FROM college.courses c
WHERE c.course_name = 'ПР16 Програмування 6 кредитів'
AND NOT EXISTS (
    SELECT 1 FROM college.enrollments e
    WHERE e.student_id = 991601
    AND e.course_id = c.course_id
);

INSERT INTO college.enrollments (student_id, course_id)
SELECT 991602, c.course_id
FROM college.courses c
WHERE c.course_name = 'ПР16 Фізика 5 кредитів'
AND NOT EXISTS (
    SELECT 1 FROM college.enrollments e
    WHERE e.student_id = 991602
    AND e.course_id = c.course_id
);

-- =====================================================
-- 2. СКАЛЯРНИЙ ПІДЗАПИТ
-- Знайти курси, дорожчі за середню плату.
-- Підзапит повертає одне значення AVG(tuition_fee).
-- =====================================================

SELECT course_name, tuition_fee
FROM college.courses
WHERE tuition_fee > (
    SELECT AVG(tuition_fee)
    FROM college.courses
)
ORDER BY tuition_fee DESC;

-- =====================================================
-- 3. БАГАТОРЯДКОВИЙ ПІДЗАПИТ IN
-- Знайти студентів, які зареєстровані на курси
-- з кількістю кредитів більше 4.
-- =====================================================

SELECT student_id, student_name
FROM college.students
WHERE student_id IN (
    SELECT e.student_id
    FROM college.enrollments e
    JOIN college.courses c
        ON e.course_id = c.course_id
    WHERE c.credits > 4
)
ORDER BY student_id;

-- =====================================================
-- 4. БАГАТОРЯДКОВІ ПІДЗАПИТИ ANY ТА ALL
-- ANY: кредити більші хоча б за один курс фізики.
-- ALL: кредити більші за кількість кредитів усіх
-- курсів підрозділу фізики.
-- =====================================================

-- ANY
SELECT course_name, credits
FROM college.courses
WHERE credits > ANY (
    SELECT c.credits
    FROM college.courses c
    JOIN college.departments d
        ON c.department_id = d.department_id
    WHERE d.code = 'S16PH'
)
ORDER BY credits;

-- ALL
SELECT course_name, credits
FROM college.courses
WHERE credits > ALL (
    SELECT c.credits
    FROM college.courses c
    JOIN college.departments d
        ON c.department_id = d.department_id
    WHERE d.code = 'S16PH'
)
ORDER BY credits;

-- =====================================================
-- 5. КОРЕЛЬОВАНИЙ ПІДЗАПИТ EXISTS
-- Знайти підрозділи, які мають хоча б один курс
-- із зареєстрованими студентами.
-- Підзапит використовує department_id зовнішнього запиту.
-- =====================================================

SELECT d.department_id, d.name
FROM college.departments d
WHERE EXISTS (
    SELECT 1
    FROM college.courses c
    JOIN college.enrollments e
        ON c.course_id = e.course_id
    WHERE c.department_id = d.department_id
)
ORDER BY d.name;

-- =====================================================
-- 6. ОДНЕ ЗАВДАННЯ ДВОМА СПОСОБАМИ
-- Знайти студентів, зареєстрованих на курси
-- з кількістю кредитів більше 4.
-- =====================================================

-- Варіант 1: за допомогою підзапиту IN
SELECT student_id, student_name
FROM college.students
WHERE student_id IN (
    SELECT e.student_id
    FROM college.enrollments e
    JOIN college.courses c
        ON e.course_id = c.course_id
    WHERE c.credits > 4
)
ORDER BY student_id;

-- Варіант 2: за допомогою JOIN
SELECT DISTINCT s.student_id, s.student_name
FROM college.students s
JOIN college.enrollments e
    ON s.student_id = e.student_id
JOIN college.courses c
    ON e.course_id = c.course_id
WHERE c.credits > 4
ORDER BY s.student_id;

-- Обидва запити знаходять однакових студентів.
-- IN використовує результат вкладеного запиту,
-- JOIN безпосередньо об'єднує таблиці.
-- DISTINCT запобігає повторенню студентів.

-- =====================================================
-- 7. ПІДЗАПИТ У СЕКЦІЇ FROM
-- Спочатку групуємо реєстрації за курсами,
-- потім зовнішній запит підсумовує їх кількість.
-- =====================================================

SELECT SUM(course_stats.registration_count)
    AS total_registrations
FROM (
    SELECT
        course_id,
        COUNT(*) AS registration_count
    FROM college.enrollments
    GROUP BY course_id
) AS course_stats;

COMMIT;

-- =====================================================
-- КІНЕЦЬ ПРАКТИЧНОЇ РОБОТИ №16
-- =====================================================

-- ВІДПОВІДІ НА КОНТРОЛЬНІ ПИТАННЯ
--
-- 1. Скалярний підзапит повертає одне значення,
--    багаторядковий може повертати декілька рядків.
--
-- 2. Якщо скалярний підзапит повертає декілька рядків,
--    PostgreSQL видає помилку.
--
-- 3. EXISTS доцільний, коли потрібно перевірити
--    наявність хоча б одного відповідного запису.
--
-- 4. Корельований підзапит використовує значення
--    зовнішнього запиту, тому логічно перевіряється
--    для кожного рядка зовнішнього запиту.
