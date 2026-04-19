import { useEffect, useRef } from 'react';
import { useWebSocketStore } from '../store/websocketStore.ts';

export function useStompSubscription<T>(
  topic: string | null,
  onMessage: (data: T) => void,
) {
  const client = useWebSocketStore((s) => s.client);
  const connected = useWebSocketStore((s) => s.connected);
  const callbackRef = useRef(onMessage);
  callbackRef.current = onMessage;

  useEffect(() => {
    if (!client || !connected || !topic) return;

    const sub = client.subscribe(topic, (message) => {
      try {
        const data = JSON.parse(message.body) as T;
        callbackRef.current(data);
      } catch (e) {
        console.error('Failed to parse WS message', e);
      }
    });

    return () => sub.unsubscribe();
  }, [client, connected, topic]);
}
