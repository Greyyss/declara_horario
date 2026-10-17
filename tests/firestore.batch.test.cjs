
const fs = require("node:fs");
const path = require("node:path");
const { test } = require("node:test");

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");

const firebase = require("firebase/compat/app");
require("firebase/compat/firestore");

const FieldValue = firebase.firestore.FieldValue;

test("Seguridad del guardado completo de declaraciones", async (t) => {
  const rules = fs.readFileSync(
    path.join(__dirname, "..", "firestore.rules"),
    "utf8"
  );

  const env = await initializeTestEnvironment({
    projectId: "declarahorario",
    firestore: {
      host: "127.0.0.1",
      port: 8080,
      rules,
    },
  });

  try {
    await env.clearFirestore();

    // Crear perfiles simulados sin aplicar las reglas.
    await env.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      await db.collection("users").doc("declarante_prueba").set({
        nombre: "Declarante de prueba",
        correo: "declarante@prueba.com",
        rol: "declarante",
        superiorId: "superior_prueba",
      });

      await db.collection("users").doc("superior_prueba").set({
        nombre: "Superior de prueba",
        correo: "superior@prueba.com",
        rol: "superior",
      });
    });

    function crearLote(db, usuarioId, declaracionId) {
      const batch = db.batch();

      const declarationRef = db
        .collection("declarations")
        .doc(declaracionId);

      const versionRef = declarationRef
        .collection("versions")
        .doc("1");

      batch.set(declarationRef, {
        usuarioId,
        superiorId: "superior_prueba",
        nombreFuncionario: "Funcionario de prueba",
        identificacion: "123456789",
        telefono: "88888888",
        correo: "declarante@prueba.com",
        unidad: "Unidad de prueba",
        periodo: "2026",
        estado: "BORRADOR",
        fechaCreacion: FieldValue.serverTimestamp(),
        versionActual: 1,
      });

      batch.set(versionRef, {
        numero: 1,
        estado: "BORRADOR",
        firmada: false,
      });

      batch.set(
        declarationRef.collection("appointments").doc("nombramiento_1"),
        {
          institucion: "UCR",
          horarios: [
            {
              dia: "Lunes",
              horaInicio: "08:00",
              horaFin: "12:00",
            },
          ],
        }
      );

      batch.set(
        versionRef.collection("appointments").doc("nombramiento_1"),
        {
          institucion: "UCR",
          horarios: [
            {
              dia: "Lunes",
              horaInicio: "08:00",
              horaFin: "12:00",
            },
          ],
        }
      );

      batch.set(
        declarationRef.collection("externalJobs").doc("trabajo_1"),
        {
          institucion: "Institución externa",
          horarios: [
            {
              dia: "Martes",
              horaInicio: "13:00",
              horaFin: "17:00",
            },
          ],
        }
      );

      batch.set(
        versionRef.collection("externalJobs").doc("trabajo_1"),
        {
          institucion: "Institución externa",
          horarios: [
            {
              dia: "Martes",
              horaInicio: "13:00",
              horaFin: "17:00",
            },
          ],
        }
      );

      batch.set(
        declarationRef.collection("events").doc("evento_creacion"),
        {
          usuarioId,
          evento: "DECLARACION_CREADA",
          estadoNuevo: "BORRADOR",
          fechaHora: FieldValue.serverTimestamp(),
        }
      );

      return batch;
    }

    await t.test(
      "1. Declarante guarda declaración completa",
      async () => {
        const db = env
          .authenticatedContext("declarante_prueba")
          .firestore();

        await assertSucceeds(
          crearLote(
            db,
            "declarante_prueba",
            "declaracion_completa"
          ).commit()
        );
      }
    );

    await t.test(
      "2. No puede guardar declaración a nombre de otro",
      async () => {
        const db = env
          .authenticatedContext("declarante_prueba")
          .firestore();

        await assertFails(
          crearLote(
            db,
            "otro_usuario",
            "declaracion_ajena"
          ).commit()
        );
      }
    );

    await t.test(
      "3. Sin iniciar sesión no puede guardar",
      async () => {
        const db = env.unauthenticatedContext().firestore();

        await assertFails(
          crearLote(
            db,
            "declarante_prueba",
            "declaracion_sin_sesion"
          ).commit()
        );
      }
    );
  } finally {
    await env.cleanup();
  }
});
