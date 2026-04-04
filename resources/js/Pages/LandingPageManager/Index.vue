<template>
    <Head title="Landing Page Manager" />

    <div class="row">
        <div class="col-12">
            <div class="card card-outline card-dark">
                <div class="card-header"><h3 class="card-title">Visibility Toggle</h3></div>
                <div class="card-body">
                    <div class="row">
                        <div v-for="field in visibilityFields" :key="field.key" class="col-md-3 mb-3">
                            <label class="d-flex align-items-center justify-content-between border rounded p-3 mb-0">
                                <span>{{ field.label }}</span>
                                <input v-model="visibilityForm[field.key]" type="checkbox">
                            </label>
                        </div>
                    </div>
                    <button type="button" class="btn btn-dark" :disabled="visibilityForm.processing" @click="submitVisibility">Simpan Visibility</button>
                </div>
            </div>
        </div>
    </div>

    <div class="row">
        <div class="col-lg-6 mb-3">
            <div class="card card-outline card-primary h-100">
                <div class="card-header"><h3 class="card-title">Hero Section</h3></div>
                <div class="card-body">
                    <div class="form-group"><label>Headline</label><input v-model="heroForm.title" type="text" class="form-control"></div>
                    <div class="form-group"><label>Description</label><textarea v-model="heroForm.description" rows="4" class="form-control"></textarea></div>
                    <div class="form-group"><label>Badge</label><input v-model="heroForm.meta_data.badge" type="text" class="form-control"></div>
                    <div class="form-group"><label>Eyebrow</label><input v-model="heroForm.meta_data.eyebrow" type="text" class="form-control"></div>
                    <div class="row">
                        <div class="col-md-6 form-group"><label>CTA Label</label><input v-model="heroForm.meta_data.cta_label" type="text" class="form-control"></div>
                        <div class="col-md-6 form-group"><label>CTA Target</label><input v-model="heroForm.meta_data.cta_href" type="text" class="form-control"></div>
                    </div>
                    <button type="button" class="btn btn-primary" :disabled="heroForm.processing" @click="submitSection(heroForm, 'hero')">Update Hero</button>
                </div>
            </div>
        </div>
        <div class="col-lg-6 mb-3">
            <div class="card card-outline card-secondary h-100">
                <div class="card-header"><h3 class="card-title">Story Intro</h3></div>
                <div class="card-body">
                    <div class="form-group"><label>Title</label><input v-model="storyForm.title" type="text" class="form-control"></div>
                    <div class="form-group"><label>Description</label><textarea v-model="storyForm.description" rows="5" class="form-control"></textarea></div>
                    <div class="form-group"><label>Kicker</label><input v-model="storyForm.meta_data.kicker" type="text" class="form-control"></div>
                    <button type="button" class="btn btn-secondary" :disabled="storyForm.processing" @click="submitSection(storyForm, 'story')">Update Story</button>
                </div>
            </div>
        </div>
    </div>

    <div class="row">
        <div v-for="note in noteSections" :key="note.key" class="col-lg-4 mb-3">
            <div class="card card-outline card-warning h-100">
                <div class="card-header"><h3 class="card-title">{{ note.label }}</h3></div>
                <div class="card-body">
                    <div class="form-group"><label>Title</label><input v-model="note.form.title" type="text" class="form-control"></div>
                    <div class="form-group"><label>Description</label><textarea v-model="note.form.description" rows="5" class="form-control"></textarea></div>
                    <button type="button" class="btn btn-warning" :disabled="note.form.processing" @click="submitSection(note.form, note.key)">Simpan {{ note.label }}</button>
                </div>
            </div>
        </div>
    </div>

    <div class="row">
        <div class="col-lg-4 mb-3">
            <div class="card card-outline card-success h-100">
                <div class="card-header"><h3 class="card-title">Ingredient Intro</h3></div>
                <div class="card-body">
                    <div class="form-group"><label>Title</label><input v-model="ingredientsIntroForm.title" type="text" class="form-control"></div>
                    <div class="form-group"><label>Description</label><textarea v-model="ingredientsIntroForm.description" rows="5" class="form-control"></textarea></div>
                    <div class="form-group"><label>Kicker</label><input v-model="ingredientsIntroForm.meta_data.kicker" type="text" class="form-control"></div>
                    <button type="button" class="btn btn-success" :disabled="ingredientsIntroForm.processing" @click="submitSection(ingredientsIntroForm, 'ingredients_intro')">Update Ingredient Intro</button>
                </div>
            </div>
        </div>

        <div class="col-lg-8 mb-3">
            <div class="card card-outline card-info h-100">
                <div class="card-header"><h3 class="card-title">Ingredient Manager</h3></div>
                <div class="card-body">
                    <div class="row">
                        <div class="col-md-5 form-group"><label>Title</label><input v-model="createIngredientForm.title" type="text" class="form-control" placeholder="New ingredient"></div>
                        <div class="col-md-4 form-group"><label>Icon</label><select v-model="createIngredientForm.icon" class="form-control"><option v-for="icon in iconOptions" :key="icon" :value="icon">{{ icon }}</option></select></div>
                        <div class="col-md-3 d-flex align-items-end form-group"><button type="button" class="btn btn-info w-100" :disabled="createIngredientForm.processing" @click="submitIngredientCreate">Tambah Ingredient</button></div>
                    </div>
                    <div class="form-group"><label>Description</label><textarea v-model="createIngredientForm.description" rows="3" class="form-control"></textarea></div>

                    <div class="table-responsive mt-4">
                        <table class="table table-hover mb-0">
                            <thead><tr><th>Title</th><th>Icon</th><th>Status</th><th>Description</th><th style="width: 180px;">Action</th></tr></thead>
                            <tbody>
                                <tr v-for="ingredient in content.ingredients" :key="ingredient.id">
                                    <td><input v-model="ingredientForms[ingredient.id].title" type="text" class="form-control form-control-sm"></td>
                                    <td><select v-model="ingredientForms[ingredient.id].icon" class="form-control form-control-sm"><option v-for="icon in iconOptions" :key="`${ingredient.id}-${icon}`" :value="icon">{{ icon }}</option></select></td>
                                    <td><select v-model="ingredientForms[ingredient.id].is_active" class="form-control form-control-sm"><option :value="true">Aktif</option><option :value="false">Nonaktif</option></select></td>
                                    <td><textarea v-model="ingredientForms[ingredient.id].description" rows="2" class="form-control form-control-sm"></textarea></td>
                                    <td>
                                        <div class="d-flex gap-2">
                                            <button type="button" class="btn btn-sm btn-warning" @click="submitIngredientUpdate(ingredient.id)">Simpan</button>
                                            <button type="button" class="btn btn-sm btn-danger" @click="submitIngredientDelete(ingredient.id)">Hapus</button>
                                        </div>
                                    </td>
                                </tr>
                                <tr v-if="!content.ingredients.length"><td colspan="5" class="text-center text-muted">Belum ada ingredient.</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { Head, router, useForm } from '@inertiajs/vue3';
import AppLayout from '../../Layouts/AppLayout.vue';
import { adminUrl } from '../../utils/admin';

defineOptions({ layout: AppLayout });

const props = defineProps({ content: Object, iconOptions: Array });
const makeSectionForm = (section) => useForm({ title: section?.title ?? '', description: section?.description ?? '', image_path: section?.image_path ?? '', is_active: section?.is_active ?? true, meta_data: { ...(section?.meta_data ?? {}) } });
const heroForm = makeSectionForm(props.content.hero);
const storyForm = makeSectionForm(props.content.story);
const ingredientsIntroForm = makeSectionForm(props.content.ingredients_intro);
const topNotesForm = makeSectionForm(props.content.notes.top_notes);
const heartNotesForm = makeSectionForm(props.content.notes.heart_notes);
const baseNotesForm = makeSectionForm(props.content.notes.base_notes);
const noteSections = [
    { key: 'top_notes', label: 'Top Notes', form: topNotesForm },
    { key: 'heart_notes', label: 'Heart Notes', form: heartNotesForm },
    { key: 'base_notes', label: 'Base Notes', form: baseNotesForm },
];
const visibilityFields = [
    { key: 'hero', label: 'Hero' },
    { key: 'story', label: 'Story Intro' },
    { key: 'notes', label: 'Scent Stages' },
    { key: 'ingredients', label: 'Ingredient Bento' },
];
const visibilityForm = useForm({ hero: props.content.visibility.hero, story: props.content.visibility.story, notes: props.content.visibility.notes, ingredients: props.content.visibility.ingredients });
const createIngredientForm = useForm({ title: '', description: '', icon: props.iconOptions[0] ?? 'spark', is_active: true });
const ingredientForms = Object.fromEntries((props.content.ingredients ?? []).map((ingredient) => [ingredient.id, useForm({ title: ingredient.title, description: ingredient.description, icon: ingredient.meta_data?.icon ?? 'spark', is_active: ingredient.is_active })]));
const submitSection = (form, section) => { form.put(adminUrl(`/landing-page-manager/sections/${section}`), { preserveScroll: true }); };
const submitVisibility = () => { visibilityForm.put(adminUrl('/landing-page-manager/visibility'), { preserveScroll: true }); };
const submitIngredientCreate = () => {
    createIngredientForm.post(adminUrl('/landing-page-manager/ingredients'), {
        preserveScroll: true,
        onSuccess: () => createIngredientForm.reset('title', 'description'),
    });
};
const submitIngredientUpdate = (id) => { ingredientForms[id].put(adminUrl(`/landing-page-manager/ingredients/${id}`), { preserveScroll: true }); };
const submitIngredientDelete = (id) => { router.delete(adminUrl(`/landing-page-manager/ingredients/${id}`), { preserveScroll: true }); };
</script>


