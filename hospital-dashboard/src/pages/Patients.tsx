import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { Search, UserSearch } from 'lucide-react';
import { listPatients, searchPatients, getPatientHistory } from '../api/patients.api.ts';
import Card from '../components/common/Card.tsx';
import Badge from '../components/common/Badge.tsx';
import { sosStatusColor, sosStatusLabel, criticalityColor } from '../utils/parseStatus.ts';
import { formatDateTime } from '../utils/formatDate.ts';
import type { PatientSearchResult, SosEvent } from '../types/index.ts';

export default function PatientsPage() {
  const navigate = useNavigate();
  const [query, setQuery] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedPatient, setSelectedPatient] = useState<number | null>(null);

  const { data: allPatients, isLoading: isLoadingList } = useQuery({
    queryKey: ['patient-list'],
    queryFn: () => listPatients(),
    select: (res) => res.data,
    enabled: searchTerm.length < 2,
  });

  const { data: searchResults, isLoading: isSearching } = useQuery({
    queryKey: ['patient-search', searchTerm],
    queryFn: () => searchPatients(searchTerm),
    select: (res) => res.data,
    enabled: searchTerm.length >= 2,
  });

  const patients = searchTerm.length >= 2 ? searchResults : allPatients ?? [];
  const isLoading = searchTerm.length >= 2 ? isSearching : isLoadingList;

  const { data: history } = useQuery({
    queryKey: ['patient-history', selectedPatient],
    queryFn: () => getPatientHistory(selectedPatient!),
    select: (res) => res.data,
    enabled: selectedPatient !== null,
  });

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    setSearchTerm(query.trim());
    setSelectedPatient(null);
  };

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-bold text-gray-900">Patient History</h1>

      <div className="flex gap-6 flex-col lg:flex-row">
        {/* Left: search bar + patient cards (cards width = form width) */}
        <div className="flex flex-col gap-4 shrink-0 w-full max-w-xl">
          <form onSubmit={handleSearch} className="flex gap-2 w-full">
            <div className="relative flex-1 min-w-0">
              <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                placeholder="Search by name or phone..."
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                className="w-full pl-9 pr-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
              />
            </div>
            <button
              type="submit"
              className="px-4 py-2 bg-primary-600 text-white rounded-lg text-sm font-medium hover:bg-primary-700 shrink-0"
            >
              Search
            </button>
          </form>

          <div
            className="overflow-y-auto space-y-2 pr-1"
            style={{ maxHeight: 'calc(100vh - 18rem)' }}
          >
            {isLoading && <p className="text-sm text-gray-400 py-2">Loading...</p>}
            {!isLoading && (!patients || patients.length === 0) && (
              <Card className="p-6 text-center">
                <UserSearch size={32} className="text-gray-300 mx-auto mb-2" />
                <p className="text-gray-400 text-sm">No patients found</p>
              </Card>
            )}
            {!isLoading &&
              (patients ?? []).map((p: PatientSearchResult) => (
                <Card
                  key={p.userId}
                  className={`p-4 cursor-pointer hover:border-primary-300 transition-colors w-full ${
                    selectedPatient === p.userId ? 'border-primary-500 ring-1 ring-primary-200' : ''
                  }`}
                >
                  <div onClick={() => setSelectedPatient(p.userId)}>
                    <p className="font-medium text-gray-900">{p.fullName}</p>
                    <p className="text-sm text-gray-500">{p.phone}</p>
                    {p.lastSosDate && (
                      <p className="text-xs text-gray-400 mt-1">
                        Last SOS: {formatDateTime(p.lastSosDate)}
                      </p>
                    )}
                  </div>
                </Card>
              ))}
          </div>
        </div>

        {/* Right: history pane */}
        <div className="flex-1 min-w-0">
          {selectedPatient && history ? (
            <Card className="p-5">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">
                History for {history.fullName}
              </h2>
              {history.sosEvents.length === 0 ? (
                <p className="text-gray-400 text-sm">No emergency history</p>
              ) : (
                <div className="space-y-3">
                  {history.sosEvents.map((sos: SosEvent) => (
                    <div
                      key={sos.id}
                      onClick={() => navigate(`/sos/${sos.id}`)}
                      className="p-3 border border-gray-100 rounded-lg hover:bg-gray-50 cursor-pointer flex items-center justify-between"
                    >
                      <div>
                        <p className="text-sm font-medium text-gray-900">SOS #{sos.id}</p>
                        <p className="text-xs text-gray-500 mt-0.5">
                          {sos.symptoms || 'No symptoms'}
                        </p>
                        <p className="text-xs text-gray-400 mt-0.5">
                          {formatDateTime(sos.createdAt)}
                        </p>
                      </div>
                      <div className="flex items-center gap-2">
                        <Badge className={sosStatusColor(sos.status)}>
                          {sosStatusLabel(sos.status)}
                        </Badge>
                        <Badge className={criticalityColor(sos.criticality)}>
                          {sos.criticality}
                        </Badge>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </Card>
          ) : (
            <Card className="p-12 text-center">
              <UserSearch size={40} className="text-gray-300 mx-auto mb-3" />
              <p className="text-gray-400">Patient history will be displayed here</p>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
}
