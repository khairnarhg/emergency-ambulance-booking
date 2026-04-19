import { Client } from '@stomp/stompjs';
import SockJS from 'sockjs-client';
import { create } from 'zustand';
import { useAuthStore } from './authStore.ts';

interface WebSocketStore {
  client: Client | null;
  connected: boolean;
  connect: () => void;
  disconnect: () => void;
}

export const useWebSocketStore = create<WebSocketStore>((set, get) => ({
  client: null,
  connected: false,

  connect: () => {
    const token = useAuthStore.getState().accessToken;
    if (!token) return;

    const existing = get().client;
    if (existing?.active) return;

    const baseUrl =
      import.meta.env.VITE_API_URL || 'http://localhost:8080';

    const client = new Client({
      webSocketFactory: () => new SockJS(`${baseUrl}/ws`) as WebSocket,
      connectHeaders: { Authorization: `Bearer ${token}` },
      reconnectDelay: 5000,
      onConnect: () => set({ connected: true }),
      onDisconnect: () => set({ connected: false }),
      onStompError: (frame) =>
        console.error('STOMP error', frame.headers['message']),
    });

    client.activate();
    set({ client });
  },

  disconnect: () => {
    const { client } = get();
    if (client) {
      client.deactivate();
      set({ client: null, connected: false });
    }
  },
}));
