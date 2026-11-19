import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Concert & Live Event Management | Intelligent Seat Reservation System',
  description: 'PES University CSE DBMS Mini-Project Aug-Dec 2026',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="dark">
      <body className="bg-zinc-950 text-zinc-100 antialiased min-h-screen selection:bg-purple-600 selection:text-white">
        {children}
      </body>
    </html>
  );
}
