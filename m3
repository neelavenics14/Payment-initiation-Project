import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";
import BackToDashboard from "../../common/components/BackToDashboard";

const BASE_URL = "http://localhost:8080/api/payroll";

export default function ManagePayroll() {
  const [batches, setBatches] = useState([]);
  const [selectedBatch, setSelectedBatch] = useState(null);
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 6;
  const navigate = useNavigate();

  const fetchBatches = async () => {
    try {
      const res = await axios.get(`${BASE_URL}/batch`);
      setBatches(res.data);
    } catch (err) {
      console.error("Failed to load batches", err);
    }
  };

  useEffect(() => {
    fetchBatches();
  }, []);

  const editBatch = (batchId) => {
    navigate("/payroll", { state: { batchId } });
  };

  const submitDraft = async (batchId) => {
    try {
      const batch = batches.find((b) => b.id === batchId);
      await axios.post(`${BASE_URL}/batch`, {
        ...batch,
        status: "Submitted",
        updatedAt: new Date().toISOString(),
      });
      fetchBatches();
    } catch (err) {
      console.error(err);
    }
  };

  const remove = async (batchId) => {
    try {
      await axios.delete(`${BASE_URL}/batch/${batchId}`);
      fetchBatches();
    } catch (err) {
      console.error(err);
    }
  };

  const viewDetails = (batch) => setSelectedBatch(batch);
  const closeModal = () => setSelectedBatch(null);

  const calculateTotalAmount = (batch) =>
    (batch.payments || []).reduce((sum, p) => sum + Number(p.amount || 0), 0);

  // Pagination
  const indexOfLast = currentPage * itemsPerPage;
  const indexOfFirst = indexOfLast - itemsPerPage;
  const currentBatches = batches.slice(indexOfFirst, indexOfLast);
  const totalPages = Math.ceil(batches.length / itemsPerPage);

  return (
    <div className="container-fluid p-0">
      <div className="card">
        <div className="card-header d-flex justify-content-between align-items-center">
          <h2>Manage Payroll</h2>
          <BackToDashboard />
        </div>

        <div className="card-body p-2">
          <div className="table-responsive">
            <table className="table table-bordered text-center align-middle mb-0">
              <thead className="table-light">
                <tr>
                  <th>Sl. No</th>
                  <th>Batch ID</th>
                  <th>Date Created</th>
                  <th>Payments Count</th>
                  <th>Total Amount</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {currentBatches.length === 0 && (
                  <tr>
                    <td colSpan="7">No payroll batches found.</td>
                  </tr>
                )}
                {currentBatches.map((b, idx) => (
                  <tr key={b.id}>
                    <td>{indexOfFirst + idx + 1}</td>
                    <td>{b.id}</td>
                    <td>
                      {b.createdAt
                        ? new Date(b.createdAt).toLocaleString()
                        : "-"}
                    </td>
                    <td>{b.payments.length}</td>
                    <td>
                      {calculateTotalAmount(b)}{" "}
                      {b.instruction?.paymentCurrency}
                    </td>
                    <td>{b.status}</td>
                    <td>
                      <button onClick={() => viewDetails(b)}>View</button>
                      {b.status === "Draft" && (
                        <>
                          <button onClick={() => editBatch(b.id)}>Edit</button>
                          <button onClick={() => submitDraft(b.id)}>
                            Submit
                          </button>
                          <button onClick={() => remove(b.id)}>Delete</button>
                        </>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          <div className="d-flex justify-content-center mt-2">
            <button
              disabled={currentPage === 1}
              onClick={() => setCurrentPage(currentPage - 1)}
            >
              Previous
            </button>
            <span className="mx-2">
              Page {currentPage} of {totalPages}
            </span>
            <button
              disabled={currentPage === totalPages}
              onClick={() => setCurrentPage(currentPage + 1)}
            >
              Next
            </button>
          </div>
        </div>
      </div>

      {/* Modal */}
      {selectedBatch && (
        <div className="modal d-block" tabIndex="-1">
          <div className="modal-dialog">
            <div className="modal-content">
              <div className="modal-header">
                <h5 className="modal-title">Batch Details</h5>
                <button
                  type="button"
                  className="btn-close"
                  onClick={closeModal}
                ></button>
              </div>
              <div className="modal-body">
                <pre>{JSON.stringify(selectedBatch, null, 2)}</pre>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
