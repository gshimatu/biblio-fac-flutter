/* eslint-disable no-console */
/**
 * Seed 30 real books into Firestore collection: books
 *
 * Usage:
 *   1) npm install firebase-admin
 *   2) set GOOGLE_APPLICATION_CREDENTIALS to your service account json path
 *   3) node scripts/seed_books_firestore.js
 *
 * Optional:
 *   node scripts/seed_books_firestore.js --dry-run
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const isDryRun = process.argv.includes('--dry-run');

const BOOKS = [
  { title: 'Clean Code', author: 'Robert C. Martin', isbn: '9780132350884', category: 'Informatique', publishedDate: '2008', description: 'A handbook of agile software craftsmanship.' },
  { title: 'The Pragmatic Programmer', author: 'Andrew Hunt, David Thomas', isbn: '9780135957059', category: 'Informatique', publishedDate: '2019', description: 'Practical techniques for effective software development.' },
  { title: 'Design Patterns', author: 'Erich Gamma et al.', isbn: '9780201633610', category: 'Informatique', publishedDate: '1994', description: 'Classic catalog of reusable object-oriented design patterns.' },
  { title: 'Refactoring', author: 'Martin Fowler', isbn: '9780134757599', category: 'Informatique', publishedDate: '2018', description: 'Improving existing code structure without changing behavior.' },
  { title: 'Introduction to Algorithms', author: 'Cormen, Leiserson, Rivest, Stein', isbn: '9780262046305', category: 'Informatique', publishedDate: '2022', description: 'Comprehensive textbook on algorithms and data structures.' },
  { title: 'Code Complete', author: 'Steve McConnell', isbn: '9780735619678', category: 'Informatique', publishedDate: '2004', description: 'Software construction best practices and engineering discipline.' },
  { title: 'Domain-Driven Design', author: 'Eric Evans', isbn: '9780321125217', category: 'Informatique', publishedDate: '2003', description: 'Tackling complexity in software design with domain modeling.' },
  { title: 'Cracking the Coding Interview', author: 'Gayle Laakmann McDowell', isbn: '9780984782857', category: 'Informatique', publishedDate: '2015', description: 'Interview prep with programming questions and solutions.' },
  { title: 'Deep Learning', author: 'Ian Goodfellow, Yoshua Bengio, Aaron Courville', isbn: '9780262035613', category: 'Intelligence Artificielle', publishedDate: '2016', description: 'Foundational textbook for deep learning theory and practice.' },
  { title: 'Artificial Intelligence: A Modern Approach', author: 'Stuart Russell, Peter Norvig', isbn: '9780134610993', category: 'Intelligence Artificielle', publishedDate: '2020', description: 'Leading textbook on artificial intelligence methods.' },
  { title: 'The Mythical Man-Month', author: 'Frederick P. Brooks Jr.', isbn: '9780201835953', category: 'Gestion de Projet', publishedDate: '1995', description: 'Essays on software project management and productivity.' },
  { title: 'Peopleware', author: 'Tom DeMarco, Timothy Lister', isbn: '9780321934116', category: 'Gestion de Projet', publishedDate: '2013', description: 'Human factors behind productive teams and organizations.' },
  { title: 'Sapiens', author: 'Yuval Noah Harari', isbn: '9780062316097', category: 'Histoire', publishedDate: '2015', description: 'A brief history of humankind from evolution to modern societies.' },
  { title: 'Thinking, Fast and Slow', author: 'Daniel Kahneman', isbn: '9780374533557', category: 'Psychologie', publishedDate: '2013', description: 'How two systems of thought shape our decisions.' },
  { title: 'Atomic Habits', author: 'James Clear', isbn: '9780735211292', category: 'Developpement Personnel', publishedDate: '2018', description: 'Practical framework for building good habits and breaking bad ones.' },
  { title: 'The Lean Startup', author: 'Eric Ries', isbn: '9780307887894', category: 'Entrepreneuriat', publishedDate: '2011', description: 'How to build startups using iterative validated learning.' },
  { title: 'Zero to One', author: 'Peter Thiel, Blake Masters', isbn: '9780804139298', category: 'Entrepreneuriat', publishedDate: '2014', description: 'Notes on building unique and defensible companies.' },
  { title: 'The Intelligent Investor', author: 'Benjamin Graham', isbn: '9780060555665', category: 'Finance', publishedDate: '2006', description: 'Classic guide to long-term value investing.' },
  { title: 'Rich Dad Poor Dad', author: 'Robert T. Kiyosaki', isbn: '9781612681139', category: 'Finance', publishedDate: '2017', description: 'Popular personal finance principles through two perspectives.' },
  { title: 'The Psychology of Money', author: 'Morgan Housel', isbn: '9780857197689', category: 'Finance', publishedDate: '2020', description: 'Timeless lessons on wealth, greed, and happiness.' },
  { title: '1984', author: 'George Orwell', isbn: '9780451524935', category: 'Litterature', publishedDate: '1950', description: 'Dystopian novel about surveillance and totalitarian control.' },
  { title: 'To Kill a Mockingbird', author: 'Harper Lee', isbn: '9780061120084', category: 'Litterature', publishedDate: '2006', description: 'Classic novel about justice and racial inequality.' },
  { title: 'The Great Gatsby', author: 'F. Scott Fitzgerald', isbn: '9780743273565', category: 'Litterature', publishedDate: '2004', description: 'A portrait of wealth, illusion, and ambition in the Jazz Age.' },
  { title: 'The Alchemist', author: 'Paulo Coelho', isbn: '9780062315007', category: 'Litterature', publishedDate: '2014', description: 'Philosophical novel about purpose, destiny, and perseverance.' },
  { title: 'Harry Potter and the Sorcerer\'s Stone', author: 'J.K. Rowling', isbn: '9780590353427', category: 'Fantasy', publishedDate: '1998', description: 'The first adventure of Harry Potter at Hogwarts.' },
  { title: 'The Hobbit', author: 'J.R.R. Tolkien', isbn: '9780547928227', category: 'Fantasy', publishedDate: '2012', description: 'Bilbo Baggins sets out on an unexpected journey.' },
  { title: 'The Lord of the Rings', author: 'J.R.R. Tolkien', isbn: '9780618640157', category: 'Fantasy', publishedDate: '2005', description: 'Epic tale of friendship and the struggle against darkness.' },
  { title: 'A Brief History of Time', author: 'Stephen Hawking', isbn: '9780553380163', category: 'Science', publishedDate: '1998', description: 'Accessible introduction to cosmology and modern physics.' },
  { title: 'The Selfish Gene', author: 'Richard Dawkins', isbn: '9780199291151', category: 'Science', publishedDate: '2006', description: 'Influential perspective on evolution centered on genes.' },
  { title: 'The Art of War', author: 'Sun Tzu', isbn: '9781599869773', category: 'Strategie', publishedDate: '2007', description: 'Ancient treatise on strategy and leadership.' },
];

function makeBookPayload(book, index) {
  const now = new Date();
  const totalCopies = 2 + (index % 5); // 2..6
  const availableCopies = Math.max(1, totalCopies - (index % 3)); // keep > 0

  return {
    title: book.title,
    author: book.author,
    isbn: book.isbn,
    description: book.description,
    coverUrl: `https://covers.openlibrary.org/b/isbn/${book.isbn}-L.jpg`,
    category: book.category,
    totalCopies,
    availableCopies,
    publishedDate: book.publishedDate,
    createdAt: now,
    updatedAt: now,
  };
}

async function initAdmin() {
  if (admin.apps.length) return;

  const serviceAccountPath = path.resolve(process.cwd(), 'service-account.json');
  const hasLocalServiceAccount = fs.existsSync(serviceAccountPath);

  if (hasLocalServiceAccount) {
    // Preferred for local seeding.
    // Uses project_id from the JSON key file to avoid project detection issues.
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id,
    });
    console.log(`[AUTH] Using service-account.json for project: ${serviceAccount.project_id}`);
    return;
  }

  // Fallback to ADC if service-account.json is not found.
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: process.env.GOOGLE_CLOUD_PROJECT || process.env.GCLOUD_PROJECT,
  });
  console.log('[AUTH] Using applicationDefault credentials (ADC).');
}

async function upsertBooks() {
  await initAdmin();
  const db = admin.firestore();
  const booksRef = db.collection('books');

  let created = 0;
  let updated = 0;

  for (let i = 0; i < BOOKS.length; i += 1) {
    const source = BOOKS[i];
    const payload = makeBookPayload(source, i);

    const existing = await booksRef.where('isbn', '==', source.isbn).limit(1).get();
    if (existing.empty) {
      if (!isDryRun) {
        await booksRef.add(payload);
      }
      created += 1;
      console.log(`[CREATE] ${source.title}`);
    } else {
      const doc = existing.docs[0];
      if (!isDryRun) {
        await doc.ref.update({
          ...payload,
          createdAt: doc.get('createdAt') || payload.createdAt,
          updatedAt: new Date(),
        });
      }
      updated += 1;
      console.log(`[UPDATE] ${source.title}`);
    }
  }

  console.log('---------------------------------------');
  console.log(`Done. created=${created}, updated=${updated}, total=${BOOKS.length}`);
  if (isDryRun) {
    console.log('Dry run mode: no data written.');
  }
}

upsertBooks().catch((err) => {
  console.error('Seeding failed:', err);
  process.exit(1);
});
