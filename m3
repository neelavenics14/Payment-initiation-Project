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

  const editBatch = (batch) => {
    navigate("/payroll", { state: { batchData: batch } });
  };

  const submitDraft = async (batchId) => {
    try {
      const batch = batches.find((b) => b.id === batchId);
      await axios.put(`${BASE_URL}/batch/${batchId}`, {
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
                    <td>{b.createdAt ? new Date(b.createdAt).toLocaleString() : "-"}</td>
                    <td>{b.payments.length}</td>
                    <td>{calculateTotalAmount(b)} {b.instruction?.paymentCurrency}</td>
                    <td>{b.status}</td>
                    <td>
                      <button className="btn btn-sm btn-info me-2" onClick={() => viewDetails(b)}>View</button>
                      {b.status === "Draft" && (
                        <>
                          <button className="btn btn-sm btn-primary me-2" onClick={() => editBatch(b)}>Edit</button>
                          <button className="btn btn-sm btn-success me-2" onClick={() => submitDraft(b.id)}>Submit</button>
                          <button className="btn btn-sm btn-outline-danger" onClick={() => remove(b.id)}>Delete</button>
                        </>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="d-flex justify-content-center mt-3">
              <button className="btn btn-secondary me-2" disabled={currentPage === 1} onClick={() => setCurrentPage((p) => p - 1)}>Prev</button>
              <span className="align-self-center">Page {currentPage} of {totalPages}</span>
              <button className="btn btn-secondary ms-2" disabled={currentPage === totalPages} onClick={() => setCurrentPage((p) => p + 1)}>Next</button>
            </div>
          )}
        </div>
      </div>

      {/* Batch Details Modal */}
      {selectedBatch && (
        <div className="modal fade show" style={{ display: "block", background: "rgba(0,0,0,0.5)" }}>
          <div className="modal-dialog modal-lg">
            <div className="modal-content">
              <div className="modal-header">
                <h5 className="modal-title">Batch Details — {selectedBatch.id}</h5>
                <button type="button" className="btn-close" onClick={closeModal}></button>
              </div>
              <div className="modal-body">
                <h6>Instruction Details</h6>
                <ul>
                  <li><strong>Currency:</strong> {selectedBatch.instruction.paymentCurrency}</li>
                  <li><strong>Debit Account:</strong> {selectedBatch.instruction.debitAccount}</li>
                  <li><strong>Date:</strong> {selectedBatch.instruction.date}</li>
                </ul>

                <h6>Payments</h6>
                <div className="table-responsive">
                  <table className="table table-sm table-bordered">
                    <thead>
                      <tr>
                        <th>Sl. No</th>
                        <th>Reference</th>
                        <th>Payee Role</th>
                        <th>Payee Name</th>
                        <th>Account Number</th>
                        <th>Amount</th>
                      </tr>
                    </thead>
                    <tbody>
                      {selectedBatch.payments.map((p, idx) => (
                        <tr key={idx}>
                          <td>{idx + 1}</td>
                          <td>{p.reference}</td>
                          <td>{p.payeeDetails}</td>
                          <td>{p.payeeName}</td>
                          <td>{p.accountNumber}</td>
                          <td>{p.amount} {selectedBatch.instruction.paymentCurrency}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={closeModal}>Close</button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
