const { test, expect } = require('@playwright/test')

async function api(page, method, path, body) {
  return page.evaluate(async ({ method, path, body }) => {
    const response = await fetch('/api' + path, {
      method,
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json', 'X-Requested-With': 'sb' },
      body: body === undefined ? undefined : JSON.stringify(body),
    })
    const data = await response.json()
    if (!response.ok) throw new Error(`${method} ${path}: ${response.status} ${data.error || ''}`)
    return data
  }, { method, path, body })
}

async function signIn(page, username, password) {
  await page.goto('/')
  await page.getByLabel('Username').fill(username)
  await page.getByLabel('Password or PIN').fill(password)
  await page.getByRole('button', { name: 'Open my stories' }).click()
}

test('admin, teacher, pupil, and parent complete a class story journey', async ({ browser, baseURL }) => {
  const adminContext = await browser.newContext()
  const admin = await adminContext.newPage()
  await signIn(admin, 'admin', 'Admin@12345')
  await expect(admin.getByRole('heading', { name: 'Choose a new password' })).toBeVisible()
  await admin.getByLabel('Current password').fill('Admin@12345')
  await admin.getByLabel('New password', { exact: true }).fill('AdminBrowserPass1')
  await admin.getByLabel('Repeat new password').fill('AdminBrowserPass1')
  await admin.getByRole('button', { name: 'Save password' }).click()
  await expect(admin.getByRole('heading', { name: /Welcome/ })).toBeVisible()

  const academicYear = '2026'
  const classroom = await api(admin, 'POST', '/classes', { name: 'E2E P6 Class', level: 'P.6', academic_year: academicYear })
  const teacher = await api(admin, 'POST', '/users', { name: 'Journey Teacher', username: 'journeyteacher', password: 'TeacherPass1', class_id: classroom.id, role: 'teacher' })
  const pupil = await api(admin, 'POST', '/users', { name: 'Journey Pupil', username: 'journeypupil', password: 'PupilPass1', class_id: classroom.id, role: 'student' })
  const parent = await api(admin, 'POST', '/users', { name: 'Journey Parent', username: 'journeyparent', password: 'ParentPass1', role: 'parent' })
  await api(admin, 'POST', '/parent-links', { parent_id: parent.id, student_id: pupil.id })
  await adminContext.close()

  const teacherContext = await browser.newContext()
  const teacherPage = await teacherContext.newPage()
  await signIn(teacherPage, 'journeyteacher', 'TeacherPass1')
  await expect(teacherPage.getByRole('heading', { name: /Welcome/ })).toBeVisible()
  const story = await api(teacherPage, 'POST', '/stories', {
    title: 'The Helpful Seed', level: 'P.6', story: 'A pupil planted a seed and watered it each day. Soon it grew into a healthy plant.',
    summary: 'A pupil cares for a seed.', source_name: 'Storybook School', licence: 'Original school-created content',
  })
  await api(teacherPage, 'PATCH', `/stories/${story.id}/publish`, { status: 'published' })
  const assessment = await api(teacherPage, 'POST', '/tests', {
    title: 'The Helpful Seed', level: 'P.6', story: 'A pupil planted a seed and watered it each day. Soon it grew into a healthy plant.',
    published: true, story_id: story.id, assessment_type: 'formative', Q: [{ type: 'mc', sec: 'Remember', marks: 1, question: 'What did the pupil plant?', opts: ['A seed', 'A stone'], ans: 'A seed' }],
  })
  await teacherContext.close()

  const pupilContext = await browser.newContext()
  const pupilPage = await pupilContext.newPage()
  await signIn(pupilPage, 'journeypupil', 'PupilPass1')
  await expect(pupilPage.getByText('The Helpful Seed')).toBeVisible()
  await api(pupilPage, 'POST', `/tests/${assessment.id}/start`, {})
  const result = await api(pupilPage, 'POST', `/tests/${assessment.id}/submit`, { answers: ['A seed'] })
  expect(result.id).toBeTruthy()
  await pupilContext.close()

  const parentContext = await browser.newContext()
  const parentPage = await parentContext.newPage()
  await signIn(parentPage, 'journeyparent', 'ParentPass1')
  await expect(parentPage.getByRole('heading', { name: 'Family dashboard' })).toBeVisible()
  await expect(parentPage.getByText('Journey Pupil', { exact: true }).first()).toBeVisible()
  await expect(parentPage.getByText('The Helpful Seed', { exact: true }).first()).toBeVisible()
  await parentContext.close()
})
