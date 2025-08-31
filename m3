import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";
import BackToDashboard from "../../common/components/BackToDashboard";

const BASE_URL = "http://localhost:8080/api/payroll";

export default function ManagePayroll() {
  const [batches, setBatches] = useState([]);
  const [selectedBatch, setSelectedBatch] = useState(null);
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

  const calculateTotalAmount = (batch) =>
    (batch.payments || []).reduce((sum, p) => sum + Number(p.amount || 0), 0);

  return (
    <div className="container-fluid p-0">
      <div className="card">
        <div className="card-header text-center d-flex justify-content-between align-items-center p-2">
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
                {batches.length === 0 && (
                  <tr>
                    <td colSpan="7">No payroll batches found.</td>
                  </tr>
                )}
                {batches.map((b, idx) => (
                  <tr key={b.id}>
                    <td>{idx + 1}</td>
                    <td>{b.id}</td>
                    <td>{b.createdAt ? new Date(b.createdAt).toLocaleString() : "-"}</td>
                    <td>{b.payments.length}</td>
                    <td>{calculateTotalAmount(b)} {b.instruction.paymentCurrency}</td>
                    <td>{b.status}</td>
                    <td>
                      <button className="btn btn-sm btn-primary me-2" onClick={() => editBatch(b.id)}>Edit</button>
                      {b.status === "Draft" && (
                        <>
                          <button className="btn btn-sm btn-success me-2" onClick={() => submitDraft(b.id)}>Submit</button>
                          <button className="btn btn-sm btn-danger" onClick={() => remove(b.id)}>Delete</button>
                        </>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
