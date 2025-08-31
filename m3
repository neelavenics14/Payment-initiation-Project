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

  // Fetch all batches
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

  // Edit a batch → redirect to PayrollPayment.js
  const editBatch = (batchId) => {
    navigate("/payroll", { state: { batchId } });
  };

  // Submit a draft batch
  const submitDraft = async (batchId) => {
    try {
      const batch = batches.find(b => b.id === batchId);
      const updated = { ...batch, status: "Submitted", updatedAt: new Date().toISOString() };
      await axios.put(`${BASE_URL}/batch/${batchId}`, updated);
      fetchBatches();
    } catch (err) {
      console.error("Failed to submit draft", err);
    }
  };

  // Delete a batch
  const remove = async (batchId) => {
    try {
      await axios.delete(`${BASE_URL}/batch/${batchId}`);
      fetchBatches();
    } catch (err) {
      console.error("Failed to delete batch", err);
    }
  };

  // View batch details
  const viewDetails = (batch) => setSelectedBatch(batch);
  const closeModal = () => setSelectedBatch(null);

  // Total amount
  const calculateTotalAmount = (batch) => (batch.payments || []).reduce((sum, p) => sum + Number(p.amount || 0), 0);

  // Download summary as .txt
  const downloadSummary = (batch) => {
    if (!batch) return;
    const instruction = batch.instruction || {};
    const payments = batch.payments || [];
    const lines = [
      `Payroll Batch Summary - ${batch.id || "-"}`,
      `Status: ${batch.status || "-"}`,
      `Created: ${batch.createdAt ? new Date(batch.createdAt).toLocaleString() : "-"}`,
      `Updated: ${batch.updatedAt ? new Date(batch.updatedAt).toLocaleString() : "-"}`,
      `Currency: ${instruction.paymentCurrency || "-"}`,
      `Debit Account: ${instruction.debitAccount || "-"}`,
      `Date: ${instruction.date || "-"}`,
      "",
      "Payments:",
      ...payments.map((p, i) => `${i + 1}. ${p.payeeName || "-"} | ${p.payeeDetails || "-"} | ${p.accountNumber || "-"} | ${p.amount || "0"} ${instruction.paymentCurrency || ""} | Ref: ${p.reference || "-"}`)
    ];
    const blob = new Blob([lines.join("\n")], { type: "text/plain" });
    const link = document.createElement("a");
    link.href = URL.createObjectURL(blob);
    link.download = `Payroll_${batch.id || "Unknown"}_Summary.txt`;
    link.click();
  };

  // Pagination
  const indexOfLast = currentPage * itemsPerPage;
  const indexOfFirst = indexOfLast - itemsPerPage;
  const currentBatches = batches.slice(indexOfFirst, indexOfLast);
  const totalPages = Math.ceil(batches.length / itemsPerPage);

  return (
    <div className="container-fluid p-0" style={{ marginTop: "0px" }}>
      <div className="card" style={{ marginTop: "0px" }}>
        <div className="card-header text-center p-2 d-flex justify-content-between align-items-center">
          <h2 className="mb-0">Manage Payroll</h2>
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
                    <td>
                      <span className={
                        "badge " + 
                        (b.status === "Approved" ? "bg-success" : 
                         b.status === "Rejected" ? "bg-danger" : 
                         b.status === "Submitted" ? "bg-warning text-dark" : "bg-secondary")
                      }>{b.status}</span>
                    </td>
                    <td className="text-nowrap">
                      <button className="btn btn-sm btn-info me-2" onClick={() => viewDetails(b)}>View</button>
                      {b.status === "Draft" && (
                        <>
                          <button className="btn btn-sm btn-primary me-2" onClick={() => editBatch(b.id)}>Edit</button>
                          <button className="btn btn-sm btn-success me-2" onClick={() => submitDraft(b.id)}>Submit</button>
                          <button className="btn btn-sm btn-outline-danger" onClick={() => remove(b.id)}>Delete</button>
                        </>
                      )}
                      {(b.status === "Approved" || b.status === "Rejected") && (
                        <button className="btn btn-sm btn-outline-primary" onClick={() => downloadSummary(b)}>Download Summary</button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {totalPages > 0 && (
            <div className="d-flex justify-content-center mt-3">
              <button className="btn btn-secondary me-2" disabled={currentPage === 1} onClick={() => setCurrentPage(p => p - 1)}>Prev</button>
              <span className="align-self-center">Page {currentPage} of {totalPages}</span>
              <button className="btn btn-secondary ms-2" disabled={currentPage === totalPages} onClick={() => setCurrentPage(p => p + 1)}>Next</button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
