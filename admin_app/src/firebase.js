import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
import { getAuth } from 'firebase/auth';

const firebaseConfig = {
  apiKey: 'AIzaSyCsjIxoSrVe469i1lNNC23TVr9u8d5OTPA',
  appId: '1:331154973220:web:76adf15377516b7935aeb1',
  messagingSenderId: '331154973220',
  projectId: 'workconnected-8cf3c',
  authDomain: 'workconnected-8cf3c.firebaseapp.com',
  storageBucket: 'workconnected-8cf3c.firebasestorage.app',
  measurementId: 'G-950R2ZJY83',
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
export const auth = getAuth(app);
